# Lab 2 — Running a TDMM Self-Assessment and Building a Roadmap

**Estimated time:** 60 minutes (90 minutes for full team version)
**Difficulty:** Beginner
**Prerequisites:** None — this lab uses reflection and the TDMM assessment framework.
**Format:** Can be completed individually; significantly more valuable as a team exercise with 3–6 participants from different functions (security, engineering, platform/DevOps, compliance).

---

## Objective

Complete a TDMM self-assessment for your organization (or a hypothetical organization using the provided scenario), identify the top three improvement priorities, and draft the first 90 days of an improvement roadmap.

---

## Part 1 — Individual Pre-Scoring (15 minutes)

Before the group discussion, each participant independently scores each domain. Use this scale:

**Scoring Guidance:**
- **Level 1**: No defined process; security is reactive; practices vary by individual or team
- **Level 2**: Basic practices exist but are applied inconsistently; some teams do it, others don't
- **Level 3**: Practices are defined, documented, and applied consistently across teams; automated where possible
- **Level 4**: Practices are measured with KPIs; data drives security investment decisions
- **Level 5**: Continuous improvement cycle; industry-leading practices; proactive security improvements

Score each domain 1–5. Be honest — the purpose is to identify gaps, not to present well.

| Domain | Your Score (1–5) | Confidence (H/M/L) | Key Evidence / Concern |
|---|---|---|---|
| 1. Source Code Security | | | |
| 2. Build and CI Pipeline Security | | | |
| 3. Artifact and Registry Security | | | |
| 4. Infrastructure Security | | | |
| 5. Secrets Management | | | |
| 6. Identity and Access Management | | | |
| 7. Runtime Security and Observability | | | |
| 8. Compliance and Governance | | | |

---

## Part 2 — Calibration Exercise (15 minutes)

For each domain, the following examples describe what Level 2 and Level 3 look like. Use these to calibrate your scores.

### Domain 1 — Source Code Security

| Level | Observable Characteristics |
|---|---|
| **1** | No pre-commit hooks; secrets committed to repos regularly; no branch protection on main |
| **2** | Some teams use pre-commit hooks; secrets detection runs for some repos; branch protection exists but is not enforced consistently |
| **3** | All repos have Gitleaks or equivalent; secrets detection is org-wide policy; all main/production branches require PR + review; CODEOWNERS enforced for sensitive paths |

### Domain 2 — Build and CI Pipeline Security

| Level | Observable Characteristics |
|---|---|
| **1** | No security scanning in pipelines; secrets stored in plaintext environment variables; no pipeline as code enforcement |
| **2** | SAST or SCA exists for some projects; results are advisory (don't block builds); some pipelines use secrets management |
| **3** | SAST and SCA in all pipelines; critical findings break the build; all secrets via secrets manager; OIDC federation for cloud access in at least one environment |

### Domain 5 — Secrets Management

| Level | Observable Characteristics |
|---|---|
| **1** | Secrets hardcoded in source code or config files; rotation done manually when remembered |
| **2** | Secrets stored in CI/CD platform secrets or simple env vars; no vault; rotation is manual but scheduled |
| **3** | HashiCorp Vault, AWS Secrets Manager, or equivalent; secrets injected at runtime (not startup); automated rotation for credentials with rotation APIs |

---

## Part 3 — Group Scoring and Gap Identification (20 minutes)

If working as a team, share your individual scores and discuss until consensus is reached. For domains with large score divergence (2+ levels difference), document the reason — divergence often reveals important blind spots or communication gaps.

**Consensus scoring table:**

| Domain | Consensus Score | Score Range (min–max) | Key Gap Identified |
|---|---|---|---|
| 1. Source Code Security | | | |
| 2. Build and CI Pipeline Security | | | |
| 3. Artifact and Registry Security | | | |
| 4. Infrastructure Security | | | |
| 5. Secrets Management | | | |
| 6. Identity and Access Management | | | |
| 7. Runtime Security and Observability | | | |
| 8. Compliance and Governance | | | |

**Overall maturity score:** _(Sum of all domains ÷ 8, rounded to 1 decimal)_

---

## Part 4 — Prioritization (10 minutes)

Apply this prioritization framework to your gap list:

**Priority 1 — Fix foundational gaps first:**
Any domain scored at Level 1 that is a prerequisite for other domains. Secrets Management at Level 1 blocks progress on Pipeline Security and IAM. Source Code Security at Level 1 means there is no foundation to build on.

**Priority 2 — Quick wins with high coverage:**
Gaps that can move from Level 1 → Level 2 or Level 2 → Level 3 with low effort and high coverage. Example: enabling Gitleaks as a pre-commit hook across all repositories is a Level 1 → Level 2 improvement that takes one afternoon and affects all developers.

**Priority 3 — Cluster improvements:**
Multiple domains that require similar capabilities. If Pipeline Security and IAM both need OIDC federation, address them together.

**Complete this table:**

| Priority | Domain | Current Level | Target Level | Why This Priority | Rough Effort |
|---|---|---|---|---|---|
| 1 | | | | | |
| 2 | | | | | |
| 3 | | | | | |

---

## Part 5 — Draft the First 90 Days (10 minutes)

For your top three priorities, draft a 90-day improvement plan:

```
Month 1 — Foundation (Weeks 1–4)
Goal: [What will be different at the end of Month 1?]
Actions:
  - Week 1: [Specific action]
  - Week 2: [Specific action]
  - Week 3: [Specific action]
  - Week 4: [Specific action]
Success metric: [How will you know this is done?]

Month 2 — Expansion (Weeks 5–8)
Goal: [What will be different at the end of Month 2?]
Actions: [...]
Success metric: [...]

Month 3 — Validation (Weeks 9–12)
Goal: [What will be different at the end of Month 3?]
Actions: [...]
Success metric: [...]
```

---

## Deliverable

A completed assessment document containing:
1. Individual and consensus scores for all 8 domains
2. Top 3 improvement priorities with rationale
3. First 90-day improvement plan with specific actions and success metrics
4. One metric you will use to track progress in each priority domain

---

## Extension: Repeat Assessment Design

Design a plan for running this assessment again in 6 months:
1. What evidence will you collect in the interim to make the next assessment more objective?
2. Who should participate to ensure the assessment is calibrated correctly?
3. What scoring drift would indicate the program is on track vs. stalling?
