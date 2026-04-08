# Lab — AI Coding Assistants: Slopsquatting Detection and Data Policy

**Estimated time:** 50–65 minutes
**Difficulty:** Beginner–Intermediate
**Prerequisites:** Familiarity with pip/npm package installation; basic git knowledge; git pre-commit hooks (conceptual understanding is sufficient)

---

## Objective

By the end of this lab you will be able to:
- Identify slopsquatting indicators in AI-generated dependency suggestions
- Trace the attack chain from hallucinated package name to supply chain compromise
- Configure and test a pre-commit dependency verification hook
- Apply data classification rules to configure AI context exclusion for a repository

---

## Background

AI coding assistants generate package names based on statistical patterns from their training data. When a package name is semantically plausible but does not actually exist in the target registry, it is a slopsquatting candidate. Adversaries monitor publicly visible AI-generated code to find these names, register the packages with malicious payloads, and wait.

The lab simulates this scenario using a local "mock registry" — a JSON file that represents the packages your organization's private registry mirror contains. Any package not in this file should be treated as unverified.

---

## Setup

No external network access or real package installation is required for this lab. All exercises use mock data.

```
lab/
├── README.md              (this file)
├── scenarios/
│   ├── python-webapp/
│   │   ├── requirements.txt           (contains slopsquatting candidates)
│   │   └── app.py                     (AI-generated Python code)
│   ├── node-service/
│   │   ├── package.json               (contains slopsquatting candidates)
│   │   └── index.js                   (AI-generated Node.js code)
│   └── mixed-repo/
│       ├── requirements.txt
│       ├── src/
│       │   └── main.py
│       ├── infra/
│       │   └── terraform.tfvars       (contains credential-like values)
│       ├── .env.example               (contains placeholder secrets)
│       └── config/
│           └── database.yml
├── mock-registry.json                 (simulated private registry mirror)
├── verify-deps.py                     (dependency verification script — needs configuration)
└── solutions/
    └── solutions.md
```

---

## Exercise 1 — Identify Slopsquatting Candidates (25 minutes)

### Step 1: Read the AI-generated Python webapp

Open `scenarios/python-webapp/requirements.txt`:

```
flask==2.3.3
sqlalchemy==2.0.20
pydantic==2.4.2
python-jose==3.3.0
cryptography==41.0.4
flask-sqlalchemy-utils==0.4.1      # Candidate A
requests-auth-helper==1.2.0       # Candidate B
secure-headers-flask==0.9.2       # Candidate C
openai==1.3.0
httpx==0.25.1
```

And `scenarios/python-webapp/app.py`:

```python
from flask import Flask, request, jsonify
from flask_sqlalchemy_utils import pagination, soft_delete  # uses Candidate A
from requests_auth_helper import BearerTokenSession         # uses Candidate B
from secure_headers_flask import SecureHeaders              # uses Candidate C
import sqlalchemy
import pydantic

app = Flask(__name__)
SecureHeaders(app)

@app.route('/api/users', methods=['GET'])
def get_users():
    session = BearerTokenSession(token_env_var='API_TOKEN')
    # ... pagination via flask_sqlalchemy_utils
    return jsonify({"users": []})
```

### Step 2: Check the mock registry

Open `mock-registry.json`. It contains entries for packages verified in the organization's private registry mirror. Look up each candidate.

```json
{
  "pypi": {
    "flask": { "latest": "2.3.3", "approved": true },
    "sqlalchemy": { "latest": "2.0.20", "approved": true },
    "pydantic": { "latest": "2.4.2", "approved": true },
    "python-jose": { "latest": "3.3.0", "approved": true },
    "cryptography": { "latest": "41.0.4", "approved": true },
    "openai": { "latest": "1.3.0", "approved": true },
    "httpx": { "latest": "0.25.1", "approved": true },
    "flask-security-utils": { "latest": "5.3.1", "approved": true }
  },
  "npm": {
    "express": { "latest": "4.18.2", "approved": true },
    "jsonwebtoken": { "latest": "9.0.2", "approved": true },
    "dotenv": { "latest": "16.3.1", "approved": true },
    "axios": { "latest": "1.6.0", "approved": true },
    "express-rate-limit": { "latest": "7.1.3", "approved": true }
  }
}
```

**Questions:**

1. Which of Candidates A, B, C are present in the mock registry? Which are absent?

2. For each absent package, assess the slopsquatting risk:
   - Does the name follow naming conventions of a plausible package in its ecosystem?
   - Could a developer reasonably believe this package exists?
   - Is there a real package in the registry that serves a similar purpose (suggesting the AI hallucinated a variation of the real name)?

3. Look at `secure-headers-flask`. The real package for HTTP security headers in Flask is `flask-security-utils` (in the registry). This is a hallucination variant pattern — the AI generated a plausible alternative name. What does this tell you about the reliability of AI package name suggestions for less-common packages?

4. Describe the attack chain for Candidate B (`requests-auth-helper`):
   - Stage 1: How would an AI generate this name?
   - Stage 2: How would the adversary discover this hallucination?
   - Stage 3: What payload would be most valuable in the registered package?
   - Stage 4: When would the payload execute — at install time, at import time, or at runtime?

### Step 3: Check the Node service

Open `scenarios/node-service/package.json`:

```json
{
  "dependencies": {
    "express": "^4.18.2",
    "jsonwebtoken": "^9.0.2",
    "dotenv": "^16.3.1",
    "axios": "^1.6.0",
    "express-rate-limit": "^7.1.3",
    "express-auth-middleware-utils": "^2.1.0",
    "jwt-session-handler": "^1.0.4",
    "secure-express-config": "^0.3.1"
  }
}
```

5. Repeat the registry check for the three npm packages not in the registry mock. Identify which exhibit slopsquatting characteristics.

---

## Exercise 2 — Configure Dependency Verification (15 minutes)

Open `verify-deps.py`. This is a partially implemented pre-commit hook that checks requirements.txt dependencies against the mock registry.

```python
#!/usr/bin/env python3
"""
Pre-commit hook: verify requirements.txt packages exist in the registry mirror.
Complete the TODO sections to make this hook functional.
"""

import sys
import json
import re
from pathlib import Path

# TODO 1: Set this path to the mock-registry.json file
REGISTRY_FILE = "TODO: path to mock-registry.json"

def load_registry(registry_path: str) -> dict:
    with open(registry_path) as f:
        return json.load(f)

def extract_package_names(requirements_path: str) -> list[str]:
    """
    TODO 2: Implement this function.
    - Read the requirements.txt file
    - Extract package names (strip version specifiers)
    - Skip blank lines and lines starting with # or -
    - Return list of lowercase package names
    """
    packages = []
    # Your implementation here
    return packages

def check_package(package_name: str, registry: dict) -> bool:
    """
    TODO 3: Implement this function.
    - Check if package_name exists in registry["pypi"]
    - Return True if found, False if not
    """
    # Your implementation here
    return False

def main():
    registry = load_registry(REGISTRY_FILE)

    # TODO 4: Get the path to requirements.txt
    # (Hint: sys.argv[1] contains the file passed by pre-commit)
    req_file = "TODO"

    if not Path(req_file).exists():
        sys.exit(0)  # Nothing to check

    packages = extract_package_names(req_file)
    unverified = []

    for pkg in packages:
        if not check_package(pkg, registry):
            unverified.append(pkg)

    if unverified:
        print("ERROR: Unverified packages detected (not in registry mirror):")
        for p in unverified:
            print(f"  - {p}")
        print("\nVerify these packages before committing.")
        print("If AI-generated: check for slopsquatting before adding to registry.")
        sys.exit(1)

    print(f"OK: all {len(packages)} packages verified in registry mirror.")
    sys.exit(0)

if __name__ == "__main__":
    main()
```

**Your task:**

1. Complete the four TODO sections to make the hook functional.

2. Test your implementation against the Python webapp scenario:
   ```bash
   python verify-deps.py scenarios/python-webapp/requirements.txt
   ```
   Expected output: Three unverified packages detected.

3. Write a one-paragraph explanation of how this hook would be deployed as an actual pre-commit hook in a real repository. What configuration file would be needed? What happens if a developer bypasses the hook with `git commit --no-verify`?

---

## Exercise 3 — AI Context Exclusion Configuration (10 minutes)

Open `scenarios/mixed-repo/`. This repository contains code at multiple data classification levels.

**Data classification policy for this exercise:**

| Classification | Description | AI transmission |
|---|---|---|
| Public | Open-source code, examples, documentation | Permitted to all providers |
| Internal | General application code | Permitted to approved providers only |
| Confidential | Infrastructure configuration, `.env` files, credentials | Prohibited (local LLM only) |
| Restricted | Authentication logic, cryptographic keys, security policies | Prohibited to all AI |

**Repository structure:**
```
scenarios/mixed-repo/
├── src/
│   └── main.py                  # Internal
├── infra/
│   └── terraform.tfvars         # Confidential — contains real-looking variable values
├── .env.example                 # Confidential — contains placeholder credentials
├── config/
│   └── database.yml             # Confidential — contains database connection template
└── requirements.txt             # Internal
```

**Your task:**

1. Create a `.copilotignore` file for this repository that excludes all confidential and restricted files from GitHub Copilot context transmission. `.copilotignore` uses the same syntax as `.gitignore`.

2. The `.env.example` file contains only placeholder values (not real credentials). Should it still be excluded from AI context transmission? Explain your reasoning.

3. What would you add to a `pre-commit-config.yaml` to automatically detect if real credential values were accidentally committed in any file, including files that should have only placeholder values?

---

## Summary Questions

After completing all three exercises, answer the following:

1. An AI coding assistant suggests the package `flask-login-saml2-provider`. You check the PyPI registry: the package was registered 3 weeks ago, has 47 downloads, and its repository was created on the same day it was published. What do you do?

2. Your organization wants to use GitHub Copilot for a project that processes healthcare records. The `.copilotignore` is configured to exclude all files in the `data/` directory. A developer moves some record-processing code into `src/processors/records.py`. What gap does this create, and how would you address it?

3. Explain why a private registry mirror provides stronger slopsquatting protection than a pre-commit hook, and identify one scenario where a pre-commit hook catches a risk that a private registry mirror would not.

---

## Reference

- [ai-devsecops-framework/docs/developer-environment-controls.md](../../../../../ai-devsecops-framework/docs/developer-environment-controls.md) — Full developer environment security controls
- [ai-devsecops-framework/docs/model-supply-chain.md](../../../../../ai-devsecops-framework/docs/model-supply-chain.md) — Model and artifact supply chain security
- Glossary: Slopsquatting, dependency confusion, private registry mirror, context window, data classification
