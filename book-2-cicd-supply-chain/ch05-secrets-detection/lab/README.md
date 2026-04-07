# Lab 5 — Detecting Secrets in CI/CD Pipelines and Repositories

**Estimated time:** 35–50 minutes
**Difficulty:** Beginner
**Prerequisites:**
- Git installed
- Python 3.9+ or Docker installed
- A GitHub account (optional — for Part 3 CI pipeline integration)

---

## Overview

You will scan a sample repository for hardcoded secrets, configure a pre-commit hook to prevent future exposures, add a Gitleaks CI step to a GitHub Actions workflow, and review a pipeline log for accidental secret exposure patterns.

---

## Setup: Install Gitleaks

```bash
# macOS
brew install gitleaks

# Linux (binary)
curl -sSfL https://raw.githubusercontent.com/gitleaks/gitleaks/main/scripts/install.sh | sh -s -- -b /usr/local/bin

# Docker (no local install required)
docker pull zricethezav/gitleaks:latest

# Verify
gitleaks version
```

---

## Part 1: Scan the Sample Repository (10 minutes)

The `examples/vulnerable-repo/` directory simulates a repository with several common secret exposure patterns.

```bash
# Scan the examples directory for secrets
gitleaks detect \
  --source examples/vulnerable-repo/ \
  --report-format json \
  --report-path gitleaks-report.json \
  --no-git

# View the findings
cat gitleaks-report.json | python3 -m json.tool | grep -A5 '"RuleID"'
```

**Using Docker:**
```bash
docker run --rm \
  -v "$(pwd)/examples/vulnerable-repo:/scan" \
  zricethezav/gitleaks:latest detect \
  --source /scan \
  --no-git \
  --report-format json \
  --report-path /scan/gitleaks-report.json
```

**Expected findings:** Gitleaks should detect at least:
- An AWS access key ID + secret key pair
- A GitHub personal access token
- A generic high-entropy string that matches a password pattern

Review each finding and identify:
1. The file and line number
2. The Gitleaks rule that triggered (e.g., `aws-access-token`, `github-pat`)
3. Whether the finding is a real secret or a false positive (the examples include one false positive — an intentionally benign base64 string)

---

## Part 2: Configure Pre-Commit Hook (10 minutes)

```bash
# Install pre-commit (if not already installed)
pip install pre-commit

# Create .pre-commit-config.yaml in a test git repository
mkdir test-repo && cd test-repo && git init

cat > .pre-commit-config.yaml << 'EOF'
repos:
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.21.2
    hooks:
      - id: gitleaks
EOF

pre-commit install
```

**Test the hook:**

```bash
# Try to commit a file with a fake AWS key
cat > test-creds.py << 'EOF'
# DO NOT COMMIT — test file only
AWS_ACCESS_KEY_ID = "AKIAIOSFODNN7EXAMPLE"
AWS_SECRET_ACCESS_KEY = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
EOF

git add test-creds.py
git commit -m "test: should be blocked"
```

Expected result: Gitleaks blocks the commit and prints the detected secrets with file/line details.

```bash
# Clean up the test file
rm test-creds.py
```

**Key observation:** The pre-commit hook operates on staged content — it runs before the commit is created. If the hook is bypassed with `git commit --no-verify`, the secret is committed and requires history rewriting to remove. The CI gate (Part 3) is the authoritative control.

---

## Part 3: Add Gitleaks to a CI Pipeline (10 minutes)

Review the GitHub Actions workflow in `examples/gitleaks-ci.yml`. This workflow:
1. Runs on every push and pull request
2. Scans the full repository history for secrets
3. Fails the pipeline if any secrets are detected
4. Uploads the Gitleaks report as a pipeline artifact

Key sections to examine:

```yaml
- name: Run Gitleaks
  uses: gitleaks/gitleaks-action@v2
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    GITLEAKS_LICENSE: ${{ secrets.GITLEAKS_LICENSE }}  # Only required for org-level scans
```

**Discussion:** The `--log-opts="--all"` flag scans the entire commit history, not just the current state. Why is this important for detecting secrets that were committed and then deleted?

---

## Part 4: Pipeline Log Audit (10 minutes)

Review `examples/pipeline-log-with-secrets.txt` — a simulated CI/CD pipeline log containing accidental secret exposure patterns.

```bash
# Search for common accidental secret patterns in pipeline logs
grep -E "(password|secret|key|token).*=.*[A-Za-z0-9+/]{20,}" \
  examples/pipeline-log-with-secrets.txt

# Look for AWS credential patterns specifically
grep -E "AKIA[0-9A-Z]{16}" examples/pipeline-log-with-secrets.txt

# Look for database connection strings
grep -E "postgresql://|mysql://|mongodb://" examples/pipeline-log-with-secrets.txt
```

Identify:
1. Which lines contain accidental secret exposure
2. Which CI/CD pattern caused the exposure (debug echo, print statement, connection string in error message)
3. What change to the pipeline code would prevent each exposure

---

## Part 5: Secret Rotation Response (5 minutes)

Review the response checklist in `examples/secret-rotation-checklist.md`. For each secret found in Part 1, complete the checklist columns:

| Secret | Rotation performed | Access logs reviewed | History rewrite required | Documented |
|--------|-------------------|---------------------|--------------------------|------------|
| AWS key | | | | |
| GitHub PAT | | | | |

**For the AWS key:**
- Where would you rotate this in the AWS console? (IAM → Security credentials)
- What time range of CloudTrail logs would you review? (From the first commit date to the rotation date)

---

## Reflection Questions

1. Gitleaks found a high-entropy string in a configuration file that turned out to be a base64-encoded test fixture — not a real credential. How would you suppress this false positive without disabling the rule entirely? (Hint: look up Gitleaks `allowlist` configuration)

2. A developer argues that pre-commit hooks are sufficient and CI pipeline checks are redundant. What are three scenarios where the CI check catches a secret that the pre-commit hook missed?

3. A secret was committed to a public GitHub repository 6 months ago and then removed in a subsequent commit. Is the secret still exposed? What would an attacker need to do to retrieve it? What is the complete remediation?
