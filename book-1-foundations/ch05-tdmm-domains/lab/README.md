# Lab — TDMM Domain Mapping and Gap Analysis

**Chapter:** 5 — The TDMM: 8 Domains, 5 Levels
**Estimated time:** 50–65 minutes
**Difficulty:** Beginner–Intermediate
**Prerequisites:** Familiarity with basic DevSecOps concepts; reading Chapter 5 before this lab is strongly recommended

---

## Objective

Apply the TDMM to a described organization. By the end of this lab you will be able to:
- Map described organizational practices to TDMM domains and maturity levels
- Identify specific gaps that prevent advancement to the next level in each domain
- Prioritize improvement actions by return on investment
- Produce a one-quarter improvement plan for the two highest-priority domains

---

## Setup

No installation required. All exercises are analytical and produce written outputs (markdown tables, brief narratives, or structured lists). Use any text editor.

---

## Scenario — Stellarworks Engineering

Stellarworks is a 200-person B2B SaaS company. Engineering team: 80 engineers across 6 product teams. Security team: 1 security engineer (recently hired), 1 part-time AppSec contractor. The company is preparing for its first SOC 2 Type II audit in 6 months.

### What Stellarworks Has

**Tooling in place:**
- GitHub for source control, GitHub Actions for CI/CD
- Dependabot enabled on all repositories (alerts only — no auto-merge)
- Snyk SCA scanning integrated into CI (configured 8 months ago; no one reviews the Snyk dashboard regularly)
- 1Password Teams for secrets management (engineering team uses it inconsistently — some teams use it, others use .env files committed to git)
- AWS Organizations with separate accounts per environment (dev/staging/production)
- Basic CloudTrail logging enabled on all AWS accounts
- No IaC — infrastructure is managed manually via the AWS console by the platform lead

**Security practices:**
- No formal threat modeling process. The security engineer does ad hoc threat reviews for high-profile features when asked.
- No pre-commit hooks. Engineers commit directly to feature branches.
- Code review is required for all PRs (minimum 1 reviewer). Security is not explicitly included in the review checklist.
- No SAST tooling in the pipeline.
- No security champion program. One engineer self-identifies as "the security person" on each team.
- Annual security training is completed by all engineers (mandatory for SOC 2).

**Incident response:**
- Two security incidents in the past 18 months (one minor credential leak, one S3 bucket misconfiguration found by a customer). Both resolved ad hoc.
- No formal incident response plan documented.
- No playbooks. The security engineer handles incidents as they arise.

**AI usage:**
- GitHub Copilot deployed for 60% of engineers (3 months ago, no security review).
- No AI usage policy. No AI system inventory.
- One team is piloting a CI-based AI tool that auto-generates unit tests (not in production).

**Compliance:**
- SOC 2 audit preparation not yet started.
- Informal change management — PRs require review but no formal change record.

---

## Exercise 1 — Domain Mapping (25 minutes)

For each TDMM domain, assess Stellarworks' current maturity level based on the scenario. Rate each domain 1–5 using the level definitions from Chapter 5. You do not need to give fractional scores — pick the highest level at which the organization demonstrably meets the criteria.

Complete the table below. Write 1–2 sentences justifying each level assignment.

```markdown
| Domain | Current Level | Justification |
|--------|---------------|---------------|
| 1 — Culture & Organization | | |
| 2 — Security Requirements | | |
| 3 — Secure Development | | |
| 4 — CI/CD Security | | |
| 5 — Cloud Security | | |
| 6 — Compliance Automation | | |
| 7 — Incident Response & Forensics | | |
| 8 — AI & Agentic Security | | |
```

**Guidance for each domain:**

Domain 1 — Culture & Organization: Does security have shared ownership across teams, or is it concentrated in one person? Is security training meaningful and current, or checkbox-only? Are there security champions?

Domain 2 — Security Requirements: Are security requirements identified at design time? Is threat modeling practiced? Are abuse cases considered?

Domain 3 — Secure Development: Is SAST in the pipeline? Are pre-commit hooks enforced? Do code reviews include security criteria? Do developers get timely security feedback?

Domain 4 — CI/CD Security: Are secrets managed properly? Are build environments ephemeral? Is there artifact signing or attestation? Is OIDC used instead of long-lived credentials?

Domain 5 — Cloud Security: Is IaC used and scanned? Is IAM tightly scoped? Is CloudTrail centralized and analyzed? Are there runtime detection controls?

Domain 6 — Compliance Automation: Is compliance evidence collected automatically or manually? Is there a continuous control monitoring program?

Domain 7 — Incident Response & Forensics: Is there a formal IR plan? Are playbooks documented and tested? Can the organization reconstruct what happened during an incident?

Domain 8 — AI & Agentic Security: Is there an AI system inventory? An AI usage policy? Are AI components subject to authorization policies or audit logging?

---

**Reference assessment** (attempt your own before reviewing):

| Domain | Current Level | Justification |
|--------|---------------|---------------|
| 1 — Culture & Organization | 2 | Annual security training in place and engineers have informal security ownership, but no security champion program, no security guild, and security responsibility is concentrated in 1 engineer rather than distributed. |
| 2 — Security Requirements | 1 | No formal threat modeling process. Security requirements are identified ad hoc when the security engineer is asked. Abuse cases are not systematically considered. |
| 3 — Secure Development | 2 | SCA scanning (Snyk) is integrated into CI, but findings are not regularly reviewed. No SAST. No pre-commit hooks. Code review exists but security is not in the checklist. Basic automated scanning exists but is not acted upon. |
| 4 — CI/CD Security | 1–2 | CI/CD exists (GitHub Actions) but secrets management is inconsistent (.env files in git = Level 1 indicator). No artifact signing, no OIDC, no ephemeral environments explicitly configured. Dependabot alerts only. |
| 5 — Cloud Security | 1 | No IaC — infrastructure managed via console. CloudTrail logging exists but is not analyzed. No CSPM, no runtime detection. Manual IAM management is high drift risk. |
| 6 — Compliance Automation | 1 | SOC 2 audit preparation not started. Evidence collection is not automated. No continuous control monitoring. Compliance is episodic. |
| 7 — Incident Response & Forensics | 1 | No formal IR plan, no playbooks, no tested response capability. Two prior incidents resolved ad hoc without documented procedures. |
| 8 — AI & Agentic Security | 1 | No AI inventory, no AI usage policy, GitHub Copilot deployed without security review. Level 1 by definition (AI-Naive). |

---

## Exercise 2 — Gap Analysis (15 minutes)

For the three lowest-scored domains from Exercise 1, identify the specific gaps that prevent advancement to Level 2.

Use the format:

```markdown
**Domain: [name]**
Current Level: [N]
Target: Level [N+1]

Level [N+1] criteria not yet met:
- [Criterion]: [What exists vs. what is required]
- [Criterion]: [What exists vs. what is required]
- [Criterion]: [What exists vs. what is required]

Specific blockers:
- [Organizational, technical, or resource constraint preventing the criterion from being met]
```

**Example for Domain 2 — Security Requirements:**
```
Domain: Security Requirements
Current Level: 1
Target: Level 2

Level 2 criteria not yet met:
- Documented threat model for at least one production system: No threat models documented. Security engineer does informal reviews but nothing is recorded.
- Security requirements included in feature specifications: Feature specs focus on functional requirements only. No security acceptance criteria.
- Abuse cases identified for authentication and access control: Not practiced.

Specific blockers:
- No standard threat modeling template or process. Engineers don't know how to run one without the security engineer.
- No requirement in the engineering process to include security requirements at the spec stage.
- The security engineer is the only person who knows threat modeling — knowledge is not distributed.
```

Complete entries for your three lowest-scored domains.

---

## Exercise 3 — Prioritization (10 minutes)

Rank all 8 domains in improvement priority order. Consider:

- **Impact:** Advancing this domain reduces the most material risk for Stellarworks in the next 6 months (SOC 2 audit context matters)
- **Effort:** How much work is required to reach Level 2? Is it primarily a process change (lower effort) or a tooling deployment (higher effort)?
- **Dependencies:** Some domain improvements depend on other domains first (e.g., Compliance Automation depends on having CI/CD Security controls to automate)

Complete the prioritization matrix:

```markdown
| Rank | Domain | Why This Priority | Level 2 Effort (Low/Med/High) | SOC 2 Impact |
|------|--------|------------------|-------------------------------|--------------|
| 1 | | | | |
| 2 | | | | |
| 3 | | | | |
| 4 | | | | |
| 5 | | | | |
| 6 | | | | |
| 7 | | | | |
| 8 | | | | |
```

---

## Exercise 4 — One-Quarter Improvement Plan (10 minutes)

Select the two highest-priority domains from Exercise 3. For each, produce a 13-week improvement plan with specific deliverables.

Use the format:

```markdown
**Domain: [name]**
Current Level: [N] → Target: Level [N+1]
Rationale for selection: [1–2 sentences]

Month 1 (Weeks 1–4):
- Deliverable: [specific, actionable outcome]
- Owner: [role, not person name — use "security engineer", "platform lead", etc.]
- Effort estimate: [Low / Medium / High]

Month 2 (Weeks 5–8):
- Deliverable: ...
- Owner: ...

Month 3 (Weeks 9–13):
- Deliverable: ...
- Owner: ...

Success criteria at 13 weeks:
- [Measurable outcome that confirms Level N+1 is achieved]
- [Measurable outcome ...]

Risks:
- [What could prevent this plan from succeeding]
```

---

## Reflection Questions

1. Stellarworks has Snyk SCA scanning integrated into CI, but "no one reviews the Snyk dashboard regularly." This scenario describes a common pattern in real organizations. How would you assess this in Domain 3? Is a tool that runs but whose output is ignored a Level 1 or Level 2 capability, and what is the implication for how you score domains in practice?

2. The scenario mentions that one team is piloting an AI test generation tool "not yet in production." For Domain 8, should you assess the pilot as in-scope for the current assessment, or score only production AI usage? What are the risks of each approach?

3. If Stellarworks prioritizes Domain 6 (Compliance Automation) first because of the SOC 2 deadline, but Domain 4 (CI/CD Security) is at Level 1, what compliance controls will be hard to automate, and what does that mean for the SOC 2 preparation plan?

---

## Framework Reference

`devsecops-maturity-model/docs/framework.md`
`devsecops-maturity-model/docs/assessment-scorecard.md`

## Learning Checkpoint

After completing this lab you should be able to:
- Apply the TDMM 8-domain structure to describe an organization's security posture with specificity
- Distinguish between having a tool and having a capability (a key assessment skill)
- Identify the specific criteria that separate one maturity level from the next
- Prioritize improvement actions using both risk impact and implementation effort
- Draft a realistic 13-week improvement plan for a targeted domain
