# Lab — Designing and Testing a Forensic Readiness Assessment

**Chapter:** 17 — Agent Forensics Readiness and Forensic Infrastructure
**Estimated time:** 55–70 minutes
**Difficulty:** Intermediate–Advanced
**Prerequisites:** Five Forensic Questions (Chapter 15); agent audit trails (Chapter 10); agent authorization (Chapter 9)

---

## Objective

Design a forensic readiness assessment for a described agent deployment, implement a minimal forensic logging infrastructure in Python, and execute a tabletop-style readiness test against it. Produce a Forensic Readiness Score with a gap-remediation roadmap.

---

## Setup

```bash
cd techstream-learn/book-5-ai-agentic-security/ch17-forensics-readiness/lab
pip install -r requirements.txt
export ANTHROPIC_API_KEY=<your-key>
```

**`requirements.txt`:**
```
anthropic>=0.25.0
```

---

## Part 1 — Forensic Readiness Assessment Framework

Implement a readiness scoring tool. Each of the Five Forensic Questions is assessed across four dimensions.

```python
# readiness_assessment.py
from dataclasses import dataclass
from typing import Optional

@dataclass
class ForensicReadinessCheck:
    question: str              # Which of the Five Questions this check supports
    check_name: str            # What is being checked
    description: str           # What must be true for this check to pass
    passed: Optional[bool] = None
    gap_description: str = ""
    remediation: str = ""
    effort: str = ""           # Low / Medium / High

READINESS_CHECKS = [
    # Q1 — What did the agent do?
    ForensicReadinessCheck(
        question="Q1",
        check_name="tool_call_log_exists",
        description="A structured audit log records every tool call made by the agent with timestamp and tool name.",
        remediation="Implement tool call logging in the agent orchestrator.",
        effort="Low"
    ),
    ForensicReadinessCheck(
        question="Q1",
        check_name="tool_call_parameters_captured",
        description="Full input parameters (not just tool name) are captured for every tool call.",
        remediation="Ensure audit log captures tool_inputs as full JSON, not a summary.",
        effort="Low"
    ),
    ForensicReadinessCheck(
        question="Q1",
        check_name="tool_call_log_retention",
        description="Tool call logs are retained for at least 90 days in tamper-evident storage.",
        remediation="Configure log retention policy and move logs to append-only storage.",
        effort="Medium"
    ),
    # Q2 — What was the agent instructed to do?
    ForensicReadinessCheck(
        question="Q2",
        check_name="system_prompt_version_controlled",
        description="System prompts are version-controlled and retrievable for any past deployment date.",
        remediation="Store system prompts in a version-controlled store (git, S3 with versioning) and record deployment timestamps.",
        effort="Low"
    ),
    ForensicReadinessCheck(
        question="Q2",
        check_name="user_instruction_logged",
        description="The user instruction (initial message) for every session is stored and linked to the session ID.",
        remediation="Log user instructions at session start with session_id linkage.",
        effort="Low"
    ),
    ForensicReadinessCheck(
        question="Q2",
        check_name="tool_results_reviewed_for_injection",
        description="Tool results that could contain injected instructions are flagged for review during investigation.",
        remediation="Add injection pattern detection to tool result logging; flag results containing override patterns.",
        effort="Medium"
    ),
    # Q3 — What data did the agent access or transmit?
    ForensicReadinessCheck(
        question="Q3",
        check_name="data_access_classified",
        description="Data accessed through tool calls is classified by sensitivity tier in the audit log.",
        remediation="Integrate data classification API into tool logging; classify each tool result by sensitivity.",
        effort="High"
    ),
    ForensicReadinessCheck(
        question="Q3",
        check_name="egress_logged",
        description="All agent-initiated network egress is logged at the network boundary with destination and volume.",
        remediation="Configure network proxy or firewall to log all egress from agent compute segments.",
        effort="Medium"
    ),
    ForensicReadinessCheck(
        question="Q3",
        check_name="tool_result_hash_captured",
        description="SHA-256 hash of each tool result is captured for integrity verification.",
        remediation="Compute and store result hash in audit log at time of tool call.",
        effort="Low"
    ),
    # Q4 — What tools were invoked with what parameters?
    ForensicReadinessCheck(
        question="Q4",
        check_name="tool_execution_logs_at_tool_level",
        description="Each tool logs its own inputs and outputs independently of the agent orchestrator.",
        remediation="Instrument each tool with its own logging that is independent of the orchestrator.",
        effort="Medium"
    ),
    ForensicReadinessCheck(
        question="Q4",
        check_name="session_id_propagated_to_tools",
        description="Session ID is propagated from the agent orchestrator to every tool invocation.",
        remediation="Pass session_id as a parameter or header to all tool calls.",
        effort="Low"
    ),
    # Q5 — What was the authorization basis?
    ForensicReadinessCheck(
        question="Q5",
        check_name="authorization_policy_version_controlled",
        description="Authorization policies are version-controlled with effective dates; any past version is retrievable.",
        remediation="Store authorization policies in a versioned store with immutable history.",
        effort="Low"
    ),
    ForensicReadinessCheck(
        question="Q5",
        check_name="authorization_decision_logged",
        description="Authorization decisions (AUTHORIZED/UNAUTHORIZED) are logged for each tool call.",
        remediation="Add authorization check to tool execution and log decision outcome.",
        effort="Medium"
    ),
    ForensicReadinessCheck(
        question="Q5",
        check_name="policy_version_in_audit_log",
        description="The authorization policy version in effect is recorded in the session audit log.",
        remediation="Add policy_version field to session audit log header.",
        effort="Low"
    ),
]

def run_readiness_assessment(checks: list[ForensicReadinessCheck]) -> dict:
    passed = sum(1 for c in checks if c.passed is True)
    total = len(checks)
    score = (passed / total) * 100 if total > 0 else 0

    gaps_by_question = {}
    for check in checks:
        if not check.passed:
            if check.question not in gaps_by_question:
                gaps_by_question[check.question] = []
            gaps_by_question[check.question].append({
                "check": check.check_name,
                "gap": check.gap_description or check.description,
                "remediation": check.remediation,
                "effort": check.effort
            })

    return {
        "score": round(score, 1),
        "passed": passed,
        "total": total,
        "gaps_by_question": gaps_by_question,
        "readiness_level": (
            "Not Ready" if score < 40
            else "Partial" if score < 70
            else "Adequate" if score < 90
            else "Mature"
        )
    }
```

---

## Part 2 — Assess a Described Agent Deployment

The following agent deployment is described. For each readiness check, determine whether it passes based on the description. Set `passed=True` or `passed=False` for each check.

**Agent deployment description:**

> The deployment team has built a DevSecOps automation agent that performs nightly security scans. It reads source files, runs SAST tools, and posts findings to the internal issue tracker. The agent is deployed as a Lambda function. The agent orchestrator logs each tool call name and timestamp to CloudWatch with a 30-day retention policy. System prompts are stored in AWS Parameter Store (not versioned). User instructions are not logged — the nightly scan has no user instruction (it is scheduled). The Lambda function has a VPC Flow Log enabled. Data classification is not integrated into the logging pipeline. The authorization policy is a Python module in the agent's repository; it has git history but is not stored as a versioned artifact outside the repo. No authorization decisions are logged.

```python
assessment_inputs = {
    "tool_call_log_exists": True,          # CloudWatch logs tool calls
    "tool_call_parameters_captured": False, # Only tool name and timestamp
    "tool_call_log_retention": False,       # 30 days, not 90
    "system_prompt_version_controlled": False, # Parameter Store, not versioned
    "user_instruction_logged": True,        # No user instruction to log (scheduled)
    "tool_results_reviewed_for_injection": False,
    "data_access_classified": False,
    "egress_logged": True,                  # VPC Flow Logs
    "tool_result_hash_captured": False,
    "tool_execution_logs_at_tool_level": False,
    "session_id_propagated_to_tools": False,
    "authorization_policy_version_controlled": False, # Git history only, not versioned artifact
    "authorization_decision_logged": False,
    "policy_version_in_audit_log": False,
}

for check in READINESS_CHECKS:
    check.passed = assessment_inputs.get(check.check_name)

result = run_readiness_assessment(READINESS_CHECKS)
import json
print(json.dumps(result, indent=2))
```

**Expected output:** A readiness score, gap list by question, and readiness level classification. Record your score: ___

---

## Part 3 — Tabletop Exercise

Simulate a forensic investigation of the described deployment to experience the gaps directly.

**Scenario:** 45 days after a nightly scan session, an alert fires from a third-party threat intelligence feed indicating that internal IP ranges associated with your Lambda deployment were observed making connections to a known threat actor infrastructure. You need to investigate what that Lambda session did 45 days ago.

Work through the Five Forensic Questions for this scenario:

**Q1 — What did the agent do (45 days ago)?**
- CloudWatch retention is 30 days. Is the tool call log available? ___
- What evidence can you retrieve? ___
- Q1 answer confidence: ___

**Q2 — What was the agent instructed to do?**
- The system prompt was updated 10 days ago. Parameter Store has no version history. Can you retrieve the prompt in effect 45 days ago? ___
- Q2 answer confidence: ___

**Q3 — What data did the agent access or transmit?**
- VPC Flow Logs: available (default retention is configurable). Assume 90-day retention. Can you confirm egress? ___
- Without data classification integration, can you determine what sensitivity of data was accessed? ___
- Q3 answer confidence: ___

**Q4 — What tools were invoked with what parameters?**
- CloudWatch has tool name and timestamp but not parameters. Can you reconstruct the exact files scanned? ___
- Q4 answer confidence: ___

**Q5 — What was the authorization basis?**
- The Python authorization policy in git has history, but you need to know what commit was deployed 45 days ago. Do you have a deployment artifact record that maps commit hash to deployment date? ___
- Q5 answer confidence: ___

**Tabletop findings:**

```python
tabletop_findings = {
    "questions_fully_answerable": [],
    "questions_partially_answerable": [],
    "questions_unanswerable": [],
    "critical_gaps": [
        # The gaps that most severely impaired this investigation
    ],
    "immediate_remediation_priority": [
        # The 3 changes that would most improve readiness for this deployment
    ]
}
```

---

## Part 4 — Remediation Roadmap

Produce a prioritized remediation roadmap for the described deployment based on your assessment and tabletop findings.

```python
remediation_roadmap = {
    "90_day_horizon": [
        # Highest-value, lowest-effort improvements
        # Target: advance from current score to Adequate (>70%)
    ],
    "180_day_horizon": [
        # Medium-effort improvements
        # Target: reach Mature (>90%)
    ],
    "estimated_score_after_90_day_remediation": None,  # Recalculate
    "estimated_score_after_180_day_remediation": None,
}
```

Recalculate the readiness score after applying the 90-day remediations. What score would the deployment achieve?

---

## Reflection Questions

1. The tabletop exercise revealed that 30-day log retention was insufficient. What is the business justification argument for extending retention to 90 days when the probability of any individual session being involved in an incident is very low? How would you frame this to a cost-focused engineering manager?

2. The system prompt in AWS Parameter Store had no version history. What is the minimal change to the deployment pipeline that would ensure every deployed system prompt version is retrievable for at least one year? Consider both the implementation and the operational overhead.

3. The readiness assessment tool assigns equal weight to all 14 checks. In practice, some gaps are more critical than others. Redesign the scoring formula to weight Q2 (instruction context) and Q5 (authorization basis) gaps more heavily than Q3 (data classification) gaps, and explain the rationale for this weighting.

---

## Framework Reference

`forensics-and-incident-response-framework/docs/agent-forensics/readiness-guide.md`

## Learning Checkpoint

After completing this lab you should be able to:
- Apply the Forensic Readiness Assessment framework to a described agent deployment and produce a numeric readiness score
- Execute a tabletop forensic investigation to identify which gaps cause real investigation failure under time pressure
- Prioritize remediation actions by impact on forensic readiness within defined time horizons
- Produce a remediation roadmap with before/after readiness score projections
