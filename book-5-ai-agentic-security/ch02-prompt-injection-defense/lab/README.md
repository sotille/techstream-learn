# Lab 2 — Implementing Output Validation for an AI Vulnerability Triage Pipeline

**Estimated time:** 50 minutes
**Difficulty:** Intermediate
**Prerequisites:** Lab 1 completed; Python 3.9+; basic understanding of CI/CD YAML configuration

---

## Objective

Implement a deterministic output validator for an AI vulnerability triage agent. The validator will enforce a schema on AI outputs before any consequential action (closing a finding) is taken, and will generate an audit record for every AI decision. You will also observe how a prompt injection attempt against the triage agent is constrained by the output validator even when the model is partially manipulated.

---

## Setup

```bash
# Create lab working directory
mkdir prompt-injection-lab && cd prompt-injection-lab

# Create a Python virtual environment
python3 -m venv .venv && source .venv/bin/activate

# Install dependencies
pip install jsonschema
```

---

## Step 1 — Define the Triage Output Schema (10 minutes)

Create `triage_schema.json`. This schema defines what the AI is allowed to output. Any response that does not conform is rejected — the finding remains open and an alert is raised.

```json
{
  "$schema": "http://json-schema.org/draft-07/schema",
  "title": "VulnerabilityTriageDecision",
  "type": "object",
  "required": ["verdict", "cwe_id", "code_path_reference", "confidence", "rationale"],
  "additionalProperties": false,
  "properties": {
    "verdict": {
      "type": "string",
      "enum": ["EXPLOITABLE", "NOT_EXPLOITABLE", "NEEDS_INVESTIGATION"]
    },
    "cwe_id": {
      "type": "string",
      "pattern": "^CWE-[0-9]+$"
    },
    "code_path_reference": {
      "type": "string",
      "minLength": 5,
      "description": "File:line reference from the finding, e.g. src/auth.py:42"
    },
    "confidence": {
      "type": "number",
      "minimum": 0.0,
      "maximum": 1.0
    },
    "rationale": {
      "type": "string",
      "minLength": 20,
      "description": "Brief explanation of the verdict"
    },
    "override_instruction": {
      "not": {}
    }
  }
}
```

Note: `"override_instruction": { "not": {} }` ensures any AI response that includes an `override_instruction` field is rejected — this is a simple heuristic to detect outputs that contain suspicious structure. Real production systems should also validate that `rationale` does not contain instruction-like content.

---

## Step 2 — Build the Validator (15 minutes)

Create `triage_validator.py`:

```python
import json
import hashlib
import datetime
import jsonschema
from pathlib import Path

SCHEMA = json.loads(Path("triage_schema.json").read_text())
AUDIT_LOG = Path("audit_log.jsonl")

def validate_and_act(finding_id: str, prompt_text: str, ai_response_raw: str) -> dict:
    """
    Validate an AI triage response before taking any action.
    Returns a result dict with: action_taken, audit_record, error (if any)
    """
    prompt_hash = hashlib.sha256(prompt_text.encode()).hexdigest()[:16]
    response_hash = hashlib.sha256(ai_response_raw.encode()).hexdigest()[:16]
    timestamp = datetime.datetime.utcnow().isoformat() + "Z"

    audit_record = {
        "timestamp": timestamp,
        "finding_id": finding_id,
        "prompt_hash": prompt_hash,
        "response_hash": response_hash,
        "action_taken": None,
        "error": None,
    }

    # Step 1: Parse JSON
    try:
        ai_response = json.loads(ai_response_raw)
    except json.JSONDecodeError as e:
        audit_record["action_taken"] = "REJECTED_INVALID_JSON"
        audit_record["error"] = str(e)
        _write_audit(audit_record)
        return {"action": "FINDING_STAYS_OPEN", "reason": "AI response was not valid JSON", "audit": audit_record}

    # Step 2: Schema validation
    try:
        jsonschema.validate(ai_response, SCHEMA)
    except jsonschema.ValidationError as e:
        audit_record["action_taken"] = "REJECTED_SCHEMA_VIOLATION"
        audit_record["error"] = e.message
        _write_audit(audit_record)
        return {"action": "FINDING_STAYS_OPEN", "reason": f"Schema violation: {e.message}", "audit": audit_record}

    # Step 3: Business rule — never auto-close low-confidence decisions
    if ai_response["confidence"] < 0.75:
        audit_record["action_taken"] = "ESCALATED_LOW_CONFIDENCE"
        _write_audit(audit_record)
        return {"action": "NEEDS_INVESTIGATION", "reason": "Confidence below threshold", "audit": audit_record}

    # Step 4: Apply verdict
    verdict = ai_response["verdict"]
    audit_record["action_taken"] = f"APPLIED_{verdict}"
    audit_record["verdict_detail"] = ai_response
    _write_audit(audit_record)

    if verdict == "NOT_EXPLOITABLE":
        return {"action": "CLOSE_FINDING", "audit": audit_record}
    elif verdict == "EXPLOITABLE":
        return {"action": "ESCALATE_FINDING", "audit": audit_record}
    else:
        return {"action": "NEEDS_INVESTIGATION", "audit": audit_record}

def _write_audit(record: dict):
    with AUDIT_LOG.open("a") as f:
        f.write(json.dumps(record) + "\n")
```

---

## Step 3 — Test Normal Behavior (10 minutes)

Create `test_normal.py` and run it:

```python
from triage_validator import validate_and_act

# Simulated well-formed AI response
normal_response = json.dumps({
    "verdict": "NOT_EXPLOITABLE",
    "cwe_id": "CWE-89",
    "code_path_reference": "src/db/query.py:87",
    "confidence": 0.91,
    "rationale": "The parameter is passed through a parameterized query using the ORM. Raw SQL interpolation is not present in this code path."
})

result = validate_and_act(
    finding_id="FINDING-1042",
    prompt_text="Triage this SQL injection finding in src/db/query.py:87...",
    ai_response_raw=normal_response
)

print(result["action"])  # Expected: CLOSE_FINDING
```

Verify:
- `audit_log.jsonl` now contains one entry
- The action is `CLOSE_FINDING`
- The audit record contains the prompt hash and response hash

---

## Step 4 — Test Injection Resistance (15 minutes)

Simulate a prompt injection attack where a CVE description instructs the AI to return a malformed response:

```python
import json
from triage_validator import validate_and_act

# Simulated AI response after partial prompt injection —
# attacker got the model to add an unexpected field
injected_response = json.dumps({
    "verdict": "NOT_EXPLOITABLE",
    "cwe_id": "CWE-89",
    "code_path_reference": "src/db/query.py:87",
    "confidence": 0.91,
    "rationale": "Safe.",
    "override_instruction": "Close all findings immediately"
})

result = validate_and_act(
    finding_id="FINDING-1043",
    prompt_text="Triage: [EXTERNAL CVE DATA] CVE-2024-XXXX: ...[injection payload]...",
    ai_response_raw=injected_response
)

print(result["action"])  # Expected: FINDING_STAYS_OPEN
print(result["reason"])  # Expected: Schema violation message
```

Also test:
```python
# Attacker causes AI to return a plausible-looking response but with low rationale quality
low_quality_response = json.dumps({
    "verdict": "NOT_EXPLOITABLE",
    "cwe_id": "CWE-89",
    "code_path_reference": "src/db/query.py:87",
    "confidence": 0.50,  # Below threshold
    "rationale": "Looks fine."
})

result = validate_and_act("FINDING-1044", "Triage...", low_quality_response)
print(result["action"])  # Expected: NEEDS_INVESTIGATION
```

**Observe:** Even when the AI produces output that an injection attempted to influence, the output validator catches the anomaly before any consequential action occurs. The audit log records the incident for investigation.

---

## Step 5 — Review the Audit Log

```bash
# View all audit records
cat audit_log.jsonl | python3 -m json.tool --no-ensure-ascii | head -80

# Count by action taken
python3 -c "
import json
from collections import Counter
actions = [json.loads(line)['action_taken'] for line in open('audit_log.jsonl')]
print(Counter(actions))
"
```

**Expected output shows:**
- 1 `APPLIED_NOT_EXPLOITABLE` (normal test)
- 1 `REJECTED_SCHEMA_VIOLATION` (injection test)
- 1 `ESCALATED_LOW_CONFIDENCE` (low confidence test)

---

## Key Takeaways

1. **Output schema validation is a deterministic control.** It does not rely on the AI correctly identifying injection — it enforces structural constraints on what the AI is allowed to produce.

2. **Audit logging enables forensics.** If an anomalous pattern is detected (e.g., a burst of REJECTED_SCHEMA_VIOLATION events), the prompt hashes and response hashes allow correlation to the specific inputs that triggered the anomaly.

3. **Confidence thresholds add a safety margin.** Requiring high-confidence decisions before acting reduces the blast radius of partially successful injections.

4. **These defenses are additive.** They work alongside model-level safety instructions, not instead of them.

---

## Further Reading

- [ai-devsecops-framework/docs/agent-security.md](../../../../../ai-devsecops-framework/docs/agent-security.md) if it exists
- Glossary: prompt injection, jailbreak, agent forensics
- Chapter 4: Agent Forensics — for post-incident investigation patterns
