# Sample TDMM Assessment — Acme Corp (Hypothetical)

**Organization:** Acme Corp (hypothetical 350-person engineering organization)
**Assessment Date:** Q1
**Participants:** CISO, VP Engineering, Platform Lead, Security Champion (backend), QA Lead
**Facilitator:** External DevSecOps consultant

---

## Individual Pre-Scores

| Domain | CISO | VP Eng | Platform | Sec. Champion | QA Lead |
|--------|------|--------|----------|---------------|---------|
| 1. Source Code Security | 2 | 3 | 3 | 2 | 2 |
| 2. Build and CI Pipeline Security | 2 | 2 | 3 | 2 | 2 |
| 3. Artifact and Registry Security | 1 | 2 | 2 | 2 | 1 |
| 4. Infrastructure Security | 2 | 2 | 3 | 2 | 2 |
| 5. Secrets Management | 1 | 2 | 2 | 1 | 1 |
| 6. Identity and Access Management | 2 | 2 | 3 | 2 | 2 |
| 7. Runtime Security and Observability | 1 | 1 | 2 | 2 | 1 |
| 8. Compliance and Governance | 3 | 2 | 2 | 2 | 3 |

---

## Consensus Scores and Gap Analysis

| Domain | Consensus Score | Range | Confidence | Key Gap |
|--------|-----------------|-------|------------|---------|
| 1. Source Code Security | 2 | 2–3 | M | Gitleaks deployed for 60% of repos; 40% have no secrets scanning. Branch protection enforced inconsistently — 3 microservices have direct pushes to main. |
| 2. Build and CI Pipeline Security | 2 | 2–3 | M | SAST (Semgrep) runs in 12 of 40 pipelines. No SCA. Break-the-build gates advisory only. OIDC not yet deployed; CI secrets in GitHub Actions environment variables. |
| 3. Artifact and Registry Security | 1 | 1–2 | L | No SBOM generation. No artifact signing. Docker images are scanned manually on an ad-hoc basis — not in pipeline. No promotion gates. |
| 4. Infrastructure Security | 2 | 2–3 | M | Checkov runs for AWS Terraform modules but not Azure. IaC changes not gated on scan results. No drift detection in place. |
| 5. Secrets Management | 2 | 1–2 | L | HashiCorp Vault deployed for production services, but 60% of dev/staging pipelines still use plaintext env vars. Manual rotation for database credentials (monthly). |
| 6. Identity and Access Management | 2 | 2–3 | M | OIDC deployed for AWS in 2 teams. Cross-account roles have excessive permissions. No formal privileged access review cadence. MFA enforced for GitHub but not AWS console for all users. |
| 7. Runtime Security and Observability | 1 | 1–2 | L | No runtime threat detection. Logs aggregated to Datadog but no security-specific alerting. No incident response playbook tested in the last 12 months. |
| 8. Compliance and Governance | 2 | 2–3 | H | SOC 2 Type I audit passed. Evidence collection is manual (spreadsheets). No automated control validation. Exception process documented but not tracked in a system. |

**Overall Maturity Score: 1.75** (Scale: 1–5)

---

## Divergence Notes

**Domain 1 (Source Code):** Platform Lead scored 3; others scored 2.
Reason: Platform Lead based score on the teams they directly support (all have pre-commit hooks).
Security Champion pointed out that 8 teams onboarded in the last year have no hooks at all.
**Lesson:** Maturity reflects the weakest link, not the average team.

**Domain 5 (Secrets Management):** CISO and QA Lead scored 1; VP Eng and Platform Lead scored 2.
Reason: Vault exists, so leadership assumed Level 2. Security Champion confirmed only 40% of
services use Vault in production; dev/staging pipelines still use raw env vars extensively.
**Lesson:** Infrastructure existence ≠ adoption. Score against actual coverage.

---

## Top 3 Priorities

| Priority | Domain | Current → Target | Rationale | Effort |
|----------|--------|-----------------|-----------|--------|
| 1 | Artifact and Registry Security | L1 → L3 | Zero SBOM or signing means no supply chain visibility. Regulatory context (EO 14028 customers) makes this urgent. SLSA Level 1 achievable in 30 days with existing GitHub Actions. | Medium |
| 2 | Secrets Management | L2 → L3 | Two dev/staging pipelines leaked AWS keys to CloudTrail in the past 6 months. Vault exists — this is a coverage problem, not an infrastructure problem. Extends OIDC work already underway. | Small |
| 3 | Runtime Security and Observability | L1 → L2 | No runtime detection means the team would not know about an active compromise. Falco on EKS clusters is a quick win — L1 → L2 in one sprint. | Small |

---

## First 90-Day Roadmap

### Month 1 — Supply Chain Visibility (Weeks 1–4)
**Goal:** SBOM generation for all container images; SLSA Level 1 provenance for all GitHub Actions builds.
- Week 1: Install Syft in all container build pipelines; generate CycloneDX SBOMs and attach as workflow artifacts
- Week 2: Enable Cosign keyless signing for all Docker images pushed to GHCR (OIDC already available)
- Week 3: Add SBOM vulnerability scan (Grype) to pipelines; set to advisory mode
- Week 4: Enable SLSA provenance generation via `slsa-github-generator` for top 10 critical services
**Success metric:** 100% of container images have an attached SBOM and Cosign signature in the registry.

### Month 2 — Secrets Coverage (Weeks 5–8)
**Goal:** All dev/staging pipelines use Vault or OIDC for secret access; no plaintext env vars for credentials.
- Week 5: Audit all GitHub Actions workflows for plaintext credential env vars; create Jira tickets for each
- Week 6–7: Migrate top 5 highest-risk pipelines to Vault Agent or OIDC-based AWS access
- Week 8: Enable Gitleaks in pre-commit hooks for the 8 teams currently without hooks
**Success metric:** Zero new secrets in plaintext env vars in PR reviews for the following month; Gitleaks coverage at 100% of repos.

### Month 3 — Runtime Visibility (Weeks 9–12)
**Goal:** Falco deployed on all EKS clusters; security alerting configured in Datadog.
- Week 9: Deploy Falco as DaemonSet on production EKS clusters using Helm
- Week 10: Configure Falco rules for top 10 MITRE ATT&CK cloud scenarios; route to Datadog Logs
- Week 11: Create Datadog alert monitors for critical Falco events (container shell, privilege escalation, credential access)
- Week 12: Run a tabletop exercise using the new Falco alerts; update incident response playbook
**Success metric:** 100% of EKS clusters have Falco deployed; at least one security alert triggered and acknowledged during tabletop.

---

## Follow-up Assessment Design

- **Next assessment:** 6 months (Q3)
- **Evidence to collect before then:** Gitleaks scan coverage %, SBOM generation rate, Falco deployment %, number of secrets-in-plaintext incidents, Vault usage by service
- **Participation:** Same 5 participants + add one cloud infrastructure engineer (currently underrepresented)
- **Scoring drift to watch for:** Domain 3 or 5 not improving by at least 1 full level in 6 months would indicate the roadmap is stalling and needs re-scoping.
