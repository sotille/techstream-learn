# Lab 1 — Detecting Slopsquatting with SCA Tooling

**Estimated time:** 45–60 minutes
**Difficulty:** Beginner–Intermediate
**Prerequisites:** Familiarity with package managers (npm, pip, or Maven); basic command-line usage

---

## Objective

By the end of this lab you will be able to:
- Identify slopsquatting characteristics in AI-generated package names
- Explain the mechanism by which slopsquatting enables supply chain compromise
- Configure a SCA-based detection check for packages not present in an approved registry
- Describe where slopsquatting detection fits in a defense-in-depth strategy

---

## Background: What Is Slopsquatting?

**Slopsquatting** is the exploitation of AI code generation hallucinations to perform supply chain attacks. When an AI coding assistant generates code that imports a dependency, it sometimes generates package names that appear plausible but do not exist in the public registry. An adversary who discovers these hallucinated names can register packages under those names in the public registry, causing any developer who runs the AI-generated code to install malicious packages.

The term "slopsquatting" combines "slop" (low-quality AI output) with "squatting" (the practice of registering names others will use). It is distinct from typosquatting, which exploits human typing errors, because the AI may generate names that bear no obvious resemblance to real packages — they are plausible-sounding confabulations, not misspellings.

**Attack chain:**
1. AI coding assistant generates an import statement referencing a non-existent package (`import fetch_retry from "node-fetch-retry-utils"`)
2. Developer does not verify the package exists before committing
3. Package enters the codebase or a code sample that is widely shared
4. Adversary discovers the hallucinated package name (by querying AI tools or scanning AI-generated code repositories)
5. Adversary registers the package in the public registry with malicious content
6. Any developer who runs `npm install` or `pip install` with the package name installs the malicious payload

The attacker does not need to compromise any legitimate package or registry account — they only need to register the package name before anyone else does.

---

## Exercise 1 — Identify Slopsquatting Candidates (15 minutes)

The following list contains 10 package names from an AI-generated `requirements.txt` file. Some are real packages available on PyPI. Some exhibit slopsquatting characteristics — they appear plausible but are AI-hallucinated names.

```
requests==2.31.0
boto3==1.28.0
aws-utils-plus==1.2.0
langchain==0.0.325
anthropic-bedrock-client==0.3.1
pydantic==2.4.2
fastapi==0.103.2
openai-response-formatter==1.0.0
cryptography==41.0.4
s3-multipart-uploader-async==2.1.0
```

**For each package, answer:**
1. Does this package name follow the naming conventions of its ecosystem?
2. Is this a name that a real library would likely have, or does it sound like an AI-generated combination of plausible terms?
3. What verification step would confirm whether this package exists and is legitimate?

**Slopsquatting indicators to look for:**
- Overly descriptive compound names that combine functionality terms with qualifiers (`-plus`, `-async`, `-utils`, `-formatter`)
- Names that combine multiple real package names or service names
- Version numbers that are plausible but either unusually high for a first release or oddly specific
- Names that would be useful but don't exist in well-known ecosystem searches

**Write your analysis for each package in the table format:**

| Package | Slopsquatting Risk | Reasoning | Verification Step |
|---------|-------------------|-----------|------------------|
| requests | Low | Established package, consistent with ecosystem conventions | pypi.org/project/requests |
| ... | ... | ... | ... |

---

## Exercise 2 — Configure Package Existence Verification (20 minutes)

One of the most effective controls against slopsquatting is verifying that packages referenced in your codebase exist in your approved registry before they are installed. This check belongs in both the pre-commit hook (developer workstation) and the CI pipeline (authoritative gate).

### Part A — Pre-Commit Hook Approach

The following Python script skeleton implements a pre-commit hook that reads a `requirements.txt` file and checks each package against PyPI.

```python
#!/usr/bin/env python3
"""
pre-commit hook: verify all packages in requirements.txt exist on PyPI.
Blocks commit if any package is not found.
"""
import sys
import urllib.request
import json

def check_package_exists(package_name: str) -> bool:
    """
    Return True if the package exists on PyPI, False otherwise.
    """
    # TODO: Implement this function.
    # PyPI JSON API endpoint: https://pypi.org/pypi/{package_name}/json
    # A 200 response means the package exists.
    # A 404 response means it does not.
    # Handle network errors gracefully (return True on network error to avoid
    # blocking commits when PyPI is unreachable).
    pass

def parse_requirements(filepath: str) -> list[str]:
    """
    Parse requirements.txt and return a list of package names (without version pins).
    """
    packages = []
    with open(filepath) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            # Strip version specifiers: ==, >=, <=, ~=, !=
            # TODO: Extract just the package name from lines like "requests==2.31.0"
            pass
    return packages

def main():
    requirements_file = "requirements.txt"
    packages = parse_requirements(requirements_file)

    not_found = []
    for package in packages:
        if not check_package_exists(package):
            not_found.append(package)

    if not_found:
        print("ERROR: The following packages were not found on PyPI:")
        for p in not_found:
            print(f"  - {p}")
        print("\nThis may indicate AI-hallucinated package names (slopsquatting risk).")
        print("Verify these package names before committing.")
        sys.exit(1)

    print(f"Package existence check passed: {len(packages)} packages verified.")
    sys.exit(0)

if __name__ == "__main__":
    main()
```

**Your task:** Implement `check_package_exists` and `parse_requirements`. The functions must handle:
- Version specifiers in requirements.txt lines (`requests==2.31.0` → `requests`)
- Comment lines and blank lines
- Network errors (return `True` on error to avoid blocking commits when PyPI is unreachable — explain why this is the right default in offline/restricted environments)

### Part B — Private Registry Mirror Approach

For organizations that use a private package registry mirror (Artifactory, Nexus, AWS CodeArtifact), a stronger control is to require that all packages must be explicitly present in the private mirror before `pip install` is permitted. This prevents both slopsquatting and dependency confusion attacks.

The configuration for pip to enforce private mirror usage:

```ini
# pip.conf (place in project root or ~/.pip/pip.conf)
[global]
# Only allow packages from the private mirror
index-url = https://artifactory.your-org.com/artifactory/api/pypi/pypi-local/simple/
# No fallback to PyPI
extra-index-url =
```

**Questions:**
1. With this configuration, what happens if an engineer adds an AI-generated package name that exists on PyPI but not in the private mirror? Is this a better or worse outcome from a security perspective compared to the PyPI check in Part A?
2. What process is required to add a new package to the private mirror, and how does that process serve as a security control?
3. What is the operational trade-off of requiring private mirror approval for all new packages?

---

## Exercise 3 — Trace a Slopsquatting Attack Chain (10 minutes)

Map the following attack chain to the detection opportunities available from Exercises 1 and 2. For each stage, identify whether and how the controls you configured would detect or block the attack.

**Attack chain:**
1. Engineer uses an AI coding assistant to write a data processing module
2. Assistant generates `import s3_multipart_upload_helper` — a plausible-sounding but non-existent package
3. Engineer does not notice; runs `pip install s3_multipart_upload_helper` — gets a "not found" error
4. Engineer searches for the package, finds nothing, assumes the AI hallucinated a name, moves on
5. Three months later, an adversary finds this hallucinated name in a public blog post where the engineer shared their code sample
6. Adversary registers `s3-multipart-upload-helper` on PyPI with a post-install hook that exfiltrates AWS credentials
7. A different engineer at the same organization uses the same AI assistant, gets the same suggestion, installs the now-malicious package

| Stage | Detection Opportunity | Control from Lab | Would It Block? |
|-------|----------------------|-----------------|----------------|
| Stage 2 (package name generated) | Pre-commit hook checks package existence | Part A script | ? |
| Stage 3 (first install attempt fails) | Engineer notices the error | Manual — no automation | ? |
| Stage 6 (package registered maliciously) | Malware scanning of packages before use | Not covered in this lab | N/A |
| Stage 7 (malicious install at second engineer) | Private mirror control | Part B configuration | ? |

**Question:** At which stage in the chain is it most valuable to add detection? Explain why earlier detection is preferable and what control addresses the earliest detectable stage.

---

## Exercise 4 — Model Weight Integrity Verification (15 minutes)

The model supply chain introduces a threat analogous to dependency confusion but targeting ML model artifacts. Unlike Python packages, model artifacts can be distributed as pickle files (which execute arbitrary code on load) or as weight files without cryptographic signing, making verification non-trivial.

### Background

A developer using a Hugging Face model in a CI pipeline adds the following to their pipeline configuration:

```yaml
- name: Load security scanning model
  run: |
    python -c "
    import torch
    model = torch.load('models/vuln-scanner-v2.pt')
    "
```

The `models/vuln-scanner-v2.pt` file was originally downloaded from an internal model registry and committed to the repository. Three months later, an audit reveals that the file hash does not match the registry record.

### Questions

**Q1:** What are the two most likely explanations for the hash mismatch? For each, describe: (a) how it could occur, and (b) what evidence in the repository or model registry would help distinguish between them.

**Q2:** PyTorch `.pt` files use Python's pickle serialization by default. What does this mean for the security risk of loading the file with `torch.load()`? What is the SafeTensors alternative, and why is it safer?

**Q3:** Redesign the pipeline step above to add integrity verification before the model is loaded. Your solution must:
- Verify the file hash against a known-good value stored outside the repository
- Fail the pipeline if the hash does not match
- Not require loading the file to verify it

Write the revised pipeline step as a shell or Python snippet.

**Q4:** The model registry stores the original SHA-256 hash of each model artifact at upload time. What additional property — beyond hash verification — would provide SLSA-equivalent provenance for a model artifact, and which tool currently provides this for ML models?

---

## Summary

Slopsquatting is an example of an AI-specific threat that emerges at Layer 1 of the AI integration surface (developer environment). It exploits the gap between AI tool trust (engineers using AI suggestions without verification) and supply chain security controls (which assume packages are intentionally chosen, not hallucinated).

The controls that address it — pre-commit package existence verification and private registry mirroring — are straightforward to implement but require deliberate deployment. They are foundational controls that belong at AI Security Maturity Level 1.

Exercise 4 extends these supply chain principles to model artifacts, which represent a distinct artifact type in the AI pipeline with specific serialization risks (pickle execution) and emerging provenance tooling (ModelScan, SafeTensors, SLSA for ML). Both threats — slopsquatting and model supply chain attacks — are addressed by the same defense-in-depth philosophy: verify before use, sign what you produce, and never trust an artifact solely because it arrived from a familiar source.

---

## Further Reading

- [ai-devsecops-framework/docs/introduction.md](../../../../../ai-devsecops-framework/docs/introduction.md) — AI integration surface taxonomy and threat overview
- Chapter 5 (in the book): AI Coding Assistants — Slopsquatting, Hallucinated Packages, and Secret Exfiltration
- Glossary: slopsquatting, dependency confusion, typosquatting, private registry mirror, AI integration surface
