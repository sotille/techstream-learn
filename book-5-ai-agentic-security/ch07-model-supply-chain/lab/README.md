# Lab 3 — Auditing AI Component Supply Chain Risk

**Estimated time:** 40 minutes
**Difficulty:** Intermediate
**Prerequisites:** Python 3.9+; pip; basic familiarity with package managers and SCA concepts

---

## Objective

Audit an AI-enabled project for supply chain risks specific to AI components: identify AI SDK dependencies, check for known vulnerabilities, verify model file integrity, and document a model provenance record.

---

## Part A — AI SDK Dependency Audit (15 minutes)

### Setup

Create a sample `requirements.txt` representing a typical AI pipeline component project:

```
# requirements.txt
anthropic>=0.25.0
langchain>=0.1.0
langchain-community>=0.0.20
openai>=1.12.0
transformers>=4.38.0
torch>=2.2.0
safetensors>=0.4.2
huggingface-hub>=0.21.0
pydantic>=2.6.0
fastapi>=0.110.0
```

### Step 1 — Identify the AI-specific dependencies

From the requirements file, classify each dependency:

```
AI SDK dependencies (highest risk — direct AI behavior control):
- anthropic: Anthropic API client
- langchain, langchain-community: LLM orchestration framework
- openai: OpenAI API client

AI model runtime dependencies (model loading/execution):
- transformers: HuggingFace model loading
- torch: PyTorch; NOTE — supports unsafe pickle-based .pt files
- safetensors: Safe model serialization format

AI utility dependencies:
- huggingface-hub: Model repository client

Application dependencies:
- pydantic, fastapi: Standard web framework dependencies
```

**Key observation:** `torch` is in your dependency tree. This means your project can load pickle-based model files, which can execute arbitrary code. If your project loads any `.pt` files, audit those loading paths.

### Step 2 — Check for pinned versions

Assess the pinning quality of the requirements file:

```bash
# Count unpinned (>=) requirements
grep ">=" requirements.txt | wc -l

# A production AI component should have all versions pinned exactly:
# anthropic==0.25.0  (not >=)
```

Create a corrected `requirements-pinned.txt`:
```
anthropic==0.25.0
langchain==0.1.16
langchain-community==0.0.38
openai==1.14.3
transformers==4.38.2
torch==2.2.1
safetensors==0.4.2
huggingface-hub==0.21.3
pydantic==2.6.3
fastapi==0.110.0
```

Pinned versions prevent silent resolution to newly published malicious packages — a key slopsquatting defense.

### Step 3 — Run a vulnerability check

Install and run Grype against the requirements file:

```bash
# Install Grype (macOS)
brew install anchore/grype/grype

# Or via curl
curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /usr/local/bin

# Scan the requirements file
grype file:requirements.txt --output table

# Output findings to JSON for programmatic processing
grype file:requirements.txt --output json > ai-sdk-findings.json

# Count findings by severity
jq '.matches | group_by(.vulnerability.severity) | map({severity: .[0].vulnerability.severity, count: length})' ai-sdk-findings.json
```

**Document:** How many High/Critical findings did you find in AI-specific dependencies vs. application dependencies? AI SDK vulnerabilities (especially in LangChain and similar frameworks) frequently involve prompt injection, code execution, and unsafe deserialization — treat them as high priority.

---

## Part B — Model File Integrity Verification (15 minutes)

### Step 1 — Generate a model checksum

Simulate generating a checksum for a model file:

```bash
# Create a placeholder model file for the exercise
echo "this represents a model weights file" > example-model.bin

# Generate SHA-256 checksum
sha256sum example-model.bin > example-model.sha256
cat example-model.sha256

# In production, you would pin this hash in your deployment configuration
```

### Step 2 — Implement pre-load verification

Create `model_loader.py` that verifies integrity before loading:

```python
import hashlib
import sys
from pathlib import Path

def verify_and_load_model(model_path: str, expected_sha256: str) -> bool:
    """
    Verify a model file's SHA-256 checksum before loading.
    Returns True if verification passes; raises on failure.
    """
    model_file = Path(model_path)

    if not model_file.exists():
        raise FileNotFoundError(f"Model file not found: {model_path}")

    # Compute actual checksum
    sha256 = hashlib.sha256()
    with open(model_file, "rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            sha256.update(chunk)
    actual = sha256.hexdigest()

    if actual != expected_sha256:
        raise ValueError(
            f"Model integrity check FAILED for {model_path}\n"
            f"  Expected: {expected_sha256}\n"
            f"  Actual:   {actual}\n"
            f"  DO NOT USE THIS MODEL — possible tampering or download corruption"
        )

    print(f"Model integrity verified: {model_path}")
    return True

if __name__ == "__main__":
    model_path = sys.argv[1]
    expected_hash = sys.argv[2]
    verify_and_load_model(model_path, expected_hash)
```

Test it:
```bash
# Get the expected hash
EXPECTED=$(sha256sum example-model.bin | cut -d' ' -f1)

# Verify (should pass)
python3 model_loader.py example-model.bin $EXPECTED

# Simulate tampering
echo "tampered" >> example-model.bin

# Verify (should fail)
python3 model_loader.py example-model.bin $EXPECTED
```

### Step 3 — Note the safetensors vs. pickle distinction

```python
# UNSAFE — pickle-based loading can execute arbitrary code
import torch
model = torch.load("model.pt")  # DO NOT DO THIS with untrusted model files

# SAFE — safetensors uses a header-only format, cannot execute code
from safetensors import safe_open
with safe_open("model.safetensors", framework="pt", device="cpu") as f:
    # Read tensor data safely
    tensor = f.get_tensor("weight")
```

**In practice:** If you must load `.pt` files from third-party sources, always verify the SHA-256 checksum and obtain the file from a source where the publisher has signed the checksum. Prefer `safetensors` for any model you control.

---

## Part C — Model Provenance Record (10 minutes)

Create a `model-provenance.json` for an AI component deployed in a pipeline:

```json
{
  "schema_version": "1.0",
  "model_id": "security-code-reviewer-v1.2",
  "created": "2026-04-01T00:00:00Z",
  "model_type": "text-classification",
  "base_model": {
    "name": "Qwen2.5-Coder-7B-Instruct",
    "source": "https://huggingface.co/Qwen/Qwen2.5-Coder-7B-Instruct",
    "sha256": "PLACEHOLDER_FILL_WITH_ACTUAL_HASH",
    "verified": false
  },
  "fine_tuning": {
    "dataset_sources": [
      {
        "name": "internal-security-reviews-2024",
        "sha256": "PLACEHOLDER",
        "review_status": "reviewed",
        "review_date": "2026-01-15",
        "reviewer": "security-team"
      }
    ],
    "training_pipeline": {
      "repo": "github.com/example/model-training",
      "commit_sha": "abc123",
      "environment": "isolated-gpu-runner",
      "deterministic": false
    }
  },
  "deployment": {
    "sha256": "PLACEHOLDER_FINAL_MODEL_HASH",
    "format": "safetensors",
    "signed_by": null,
    "note": "Signing not yet implemented — target Q3 2026"
  },
  "behavioral_tests": {
    "test_suite": "security-reviewer-behavioral-tests-v1",
    "last_run": "2026-04-01",
    "pass_rate": 0.97,
    "known_failure_categories": []
  }
}
```

**Observe:** This provenance record has several gaps — unverified base model hash, no signing, non-deterministic training. These are realistic gaps for a first-generation model deployment. The value of the record is that it makes the gaps explicit and trackable. A provenance record with known gaps is far better than no provenance record, because it creates the inventory needed to close those gaps over time.

---

## Key Takeaways

1. **AI SDK dependencies carry vulnerability risk** just like web framework dependencies. Pin versions; run SCA; treat AI SDK security updates as priority patches.

2. **Model file integrity is not automatic.** Implement checksum verification as a blocking step before model loading in production.

3. **Prefer safe serialization.** `safetensors` cannot execute arbitrary code during deserialization; pickle-based formats can. This is a concrete, actionable risk reduction that costs almost nothing.

4. **A model provenance record with gaps is better than none.** Start tracking provenance now and close gaps iteratively.

---

## Further Reading

- [software-supply-chain-security-framework](../../../../../software-supply-chain-security-framework/README.md) — SBOM and supply chain security framework
- Glossary: slopsquatting, model poisoning, SLSA, SBOM
- Chapter 1: AI Pipeline Risks — for the broader threat landscape

