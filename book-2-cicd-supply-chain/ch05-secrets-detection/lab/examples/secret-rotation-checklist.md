# Secret Rotation Response Checklist

Use this checklist when a credential exposure is confirmed. Complete steps in order.
Do not skip rotation to assess blast radius first — the credential is compromised immediately upon exposure.

---

## Immediate Response (within 15 minutes of confirmation)

- [ ] **Rotate the credential** — Generate a new credential before doing anything else
  - AWS IAM key: IAM console → Security credentials → Create access key, then deactivate old key
  - GitHub PAT: Settings → Developer settings → Personal access tokens → Revoke + regenerate
  - Database password: ALTER USER command (test rollback first if app is running)
  - Stripe key: Stripe dashboard → Developers → API keys → Roll key
- [ ] **Update all consumers** — Replace the rotated credential everywhere it was used (pipelines, secrets managers, configuration)
- [ ] **Verify functionality** — Confirm the new credential works before deactivating the old one

## Scope Assessment (within 1 hour)

- [ ] **Identify exposure window** — When was the secret first committed? When was it publicly accessible (if ever)?
- [ ] **Identify all exposure surfaces** — Repository? Pipeline logs? Container images? Deployment artifacts?
- [ ] **Review access logs** — For the exposure window, review cloud provider / SaaS access logs for unauthorized use
  - AWS: CloudTrail Events filtered by AccessKeyId = [old key] for dates within exposure window
  - GitHub: Audit log filtered by actor using the exposed PAT
  - Stripe: Dashboard → Logs → API requests for the exposure window

## Remediation (within 24 hours)

- [ ] **Remove from current state** — Delete the file or line containing the secret; open a PR
- [ ] **Remove from git history** — Use `git filter-repo` to rewrite history:
  ```bash
  pip install git-filter-repo
  git filter-repo --path-glob '*.env' --invert-paths  # Remove entire file
  # OR to redact a specific string:
  git filter-repo --replace-text <(echo 'AKIAIOSFODNN7EXAMPLE==>REDACTED')
  ```
- [ ] **Force-push to all remotes** — `git push --force --all origin`
- [ ] **Notify all contributors** — They must re-clone; their local copies still have the secret in history
- [ ] **Confirm no cached copies** — Check CI/CD artifact retention, container image history, GitHub cache

## Documentation (within 48 hours)

- [ ] **Create incident record** — Date/time, secret type, exposure window, remediation steps taken
- [ ] **Root cause analysis** — How did this get committed? (Missing .gitignore, absent pre-commit hook, debug code not removed)
- [ ] **Preventive controls added** — Document what was added to prevent recurrence (pre-commit hook, CI gate, .gitignore update)
- [ ] **Audit evidence filed** — For SOC 2 / PCI-DSS: file the incident record and remediation evidence in the compliance artifact store

---

## Post-Incident Review Questions

1. Was this detectable before it reached the repository? (Pre-commit hook would have caught it)
2. Was this detectable at commit time? (CI pipeline Gitleaks scan would have caught it)
3. How long was the credential active after exposure before it was rotated?
4. Was there any unauthorized use during the exposure window?
5. What process change prevents this class of exposure in the future?
