# Chapter 5 — Detecting Secrets in CI/CD Pipelines and Repositories

**Volume:** Book 2 — Securing CI/CD & the Software Supply Chain
**Framework reference:** [devsecops-framework: secret-lifecycle-management.md](../../../../devsecops-framework/docs/secret-lifecycle-management.md) | [secure-ci-cd-reference-architecture: best-practices.md](../../../../secure-ci-cd-reference-architecture/docs/best-practices.md)

---

## What You Will Learn

Hardcoded credentials — API keys, database passwords, private keys, OAuth tokens — are among the most commonly exploited vulnerabilities in software supply chains. They appear in repositories, CI/CD pipeline logs, Docker images, and deployment artifacts with surprising regularity. Unlike vulnerability findings that require exploitation skill, exposed secrets often require only a search and an HTTP request to exploit.

By the end of this chapter, you will understand:

1. **Where secrets appear in CI/CD systems** — repositories, pipeline logs, environment variables, built artifacts, and container images
2. **Detection tooling** — Gitleaks, truffleHog, and GitHub's native secret scanning; their detection mechanisms and trade-offs
3. **Pre-commit prevention** — how to block secrets before they are ever committed using pre-commit hooks
4. **Response to a secret exposure** — the correct response sequence, including credential rotation and log sanitization
5. **Secrets inventory management** — building a baseline understanding of where secrets are legitimately stored and monitoring for drift

---

## Where Secrets Hide in CI/CD Systems

### Git Repositories

The most well-known location. Developers commit `.env` files, hardcode credentials for quick testing, or copy examples from documentation that include real tokens. Git history makes this particularly dangerous — even after a secret is deleted from the current state of a file, it remains accessible in every commit that contained it.

**Common patterns:**
- Direct credential assignment: `AWS_SECRET_KEY = "AKIAI..."`
- Database connection strings: `postgresql://admin:password@host/db`
- Private keys committed as files: `id_rsa`, `service-account.json`
- `.env` files not listed in `.gitignore`

### Pipeline Logs

CI/CD pipelines that print environment variables for debugging, or commands that echo values before using them, can expose secrets in build logs. Many CI/CD platforms (GitHub Actions, GitLab CI) automatically mask secrets registered as variables — but only secrets that are explicitly registered. Ad hoc secrets printed with `echo` are not masked.

**Example of an accidental exposure:**
```bash
# Developer adds this for debugging — secrets are logged
- run: echo "Connecting to $DATABASE_URL"
```

### Container Images

Secrets baked into container images through `RUN` directives, `COPY` of `.env` files, or `ARG` build arguments that persist in image layers. Even if a secret is removed in a later layer, it remains accessible in the intermediate layer history.

### Deployment Artifacts

Terraform state files, Helm values files, Kubernetes Secret objects stored in Git (rather than a secrets manager), and CloudFormation template outputs can all contain credentials that are not obviously secrets to the engineers who created them.

---

## Detection Tooling

### Gitleaks

Gitleaks is the most widely deployed repository secrets scanner. It uses pattern matching (regex rules covering 160+ credential types) plus entropy analysis to detect credentials in:
- Current repository state (`gitleaks detect`)
- Full commit history (`gitleaks detect --log-opts="--all"`)
- CI pipeline diffs (via `gitleaks protect` in pre-commit mode)

**Key feature:** Gitleaks maintains a curated rule set that maps to specific credential types (AWS, GCP, GitHub, Stripe, etc.) with separate rules for the key ID (low entropy, identifiable pattern) and the secret value (high entropy). This reduces false positives compared to entropy-only detection.

### truffleHog

truffleHog v3 uses verification-based detection — it not only identifies potential secrets but attempts to verify them against the relevant service. A Stripe test key that fails Stripe's API validation is flagged as inactive. This dramatically reduces false positives at the cost of making outbound API calls during the scan.

### GitHub Secret Scanning

GitHub's native secret scanning runs on all repositories (public repos free, private repos require Advanced Security) and uses a push protection feature that blocks pushes containing detected secrets before they reach the repository. GitHub maintains partnerships with cloud providers and SaaS vendors to enable real-time revocation of detected credentials.

---

## Pre-Commit Prevention

The cheapest place to catch a secret is before it is committed. The `pre-commit` framework makes this straightforward:

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.21.2
    hooks:
      - id: gitleaks
```

Install and activate:
```bash
pip install pre-commit
pre-commit install
```

After installation, every `git commit` runs Gitleaks against the staged changes. A detected secret blocks the commit with the file, line, and rule that triggered the finding.

**Important:** Pre-commit hooks are a developer workstation control — they are bypassed if the developer commits with `--no-verify`. The CI pipeline check is the authoritative gate.

---

## Responding to a Secret Exposure

When a secret is confirmed exposed in a repository or pipeline log, the response sequence is:

1. **Rotate the credential immediately** — Do not wait to understand the blast radius first. The credential is compromised from the moment it was exposed; continued use extends the exposure window.
2. **Assess the exposure scope** — When was it committed? Is it in the commit history only, or also in pipeline logs, artifacts, or deployments? Was the repository public at any point?
3. **Revoke access** — If the credential granted cloud or service access, review the access logs for the period since the exposure for unauthorized use.
4. **Remove from history** — Use `git filter-repo` (not `git filter-branch`) to remove the secret from commit history. Force-push to all remotes. Notify all contributors to re-clone.
5. **Document** — Record the finding, response timeline, and remediation in the incident log. This is required evidence for SOC 2 and PCI-DSS audits.

---

## Lab Exercise

The lab for this chapter walks through:

1. Installing Gitleaks and scanning a sample repository with intentionally embedded secrets
2. Configuring a pre-commit hook to block future secret commits
3. Adding a CI pipeline step that fails on secret detection
4. Practicing the secret rotation response procedure
5. Reviewing pipeline log output for accidental secret exposure patterns

See [lab/README.md](lab/README.md) to begin.

---

## Further Reading

- [devsecops-framework: secret-lifecycle-management.md](../../../../devsecops-framework/docs/secret-lifecycle-management.md) — full secret lifecycle management model, from creation to rotation to revocation
- [secure-ci-cd-reference-architecture: best-practices.md](../../../../secure-ci-cd-reference-architecture/docs/best-practices.md) — pipeline secrets management patterns
- [Chapter 3 (Book 2) — OIDC Keyless Authentication](../ch03-oidc-keyless/README.md) — eliminating long-lived secrets in CI/CD entirely
