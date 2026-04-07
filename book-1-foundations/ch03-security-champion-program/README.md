# Chapter 3 — Designing and Launching a Security Champion Program

**Volume:** Book 1 — DevSecOps: Foundations & Transformation
**Framework reference:** [devsecops-methodology: security-champion-program.md](../../../../devsecops-methodology/docs/security-champion-program.md) | [devsecops-methodology: framework.md](../../../../devsecops-methodology/docs/framework.md)

---

## What You Will Learn

DevSecOps cannot succeed if security knowledge lives only in the security team. At the scale of modern engineering organizations, there are never enough security engineers to review every pull request, attend every design discussion, or provide timely guidance to every team. The security champion model solves this structural problem by developing distributed security expertise embedded within engineering teams.

By the end of this chapter, you will understand:

1. **Why centralized security teams become bottlenecks** — and the structural arguments for distributing security ownership
2. **The security champion role** — what it is, what it is not, and how it differs from embedding a security engineer on a team
3. **Selection criteria** — what characteristics predict a successful security champion
4. **Program structure** — training, enablement, recognition, and the career path for security champions
5. **Common failure modes** — why most security champion programs stall in the first six months and how to prevent it

---

## Why Centralized Security Fails at Scale

Most organizations have one security engineer for every 30–100 developers. At that ratio, a security team acting as a gate — reviewing designs, approving deployments, signing off on features — becomes the bottleneck on every team's delivery velocity. When security becomes the slowdown, engineering teams route around it. Requirements get approved retrospectively. Reviews happen too late to influence design. Security becomes a checkbox rather than an input.

The security champion model does not eliminate the central security team. It extends the team's reach by developing security-aware engineers embedded within product teams who can:

- Answer first-order security questions without escalating to the central team
- Raise security concerns early in design and implementation
- Identify and remediate common vulnerability classes in their area of the codebase
- Act as the communication bridge between their team and the central security team

A security champion is not a replacement for a security engineer. The role is best described as a security-aware engineer who bridges two teams — not a developer asked to do a security engineer's job.

---

## The Security Champion Role

Security champions are typically senior or mid-level engineers who express interest in security, either intrinsically or because they have experienced the cost of a security failure on their team. They continue performing their normal engineering role — they are not reassigned to the security team.

**What security champions do:**
- Participate in the security guild or community of practice
- Attend periodic security training relevant to their stack (e.g., OWASP Top 10, secrets management, dependency hygiene)
- Review security-relevant pull requests on their team (authentication changes, input handling, permission checks)
- Own the triage and remediation of medium-severity vulnerabilities surfaced in their team's services
- Escalate high-severity findings to the central security team with context
- Represent their team's constraints and requirements in security planning discussions

**What security champions do not do:**
- Perform penetration testing or offensive security research (this requires specialized training)
- Approve security exceptions unilaterally (exceptions require central security team sign-off)
- Own the security of adjacent teams or organization-wide policy

---

## Selection and Program Structure

Effective security champion programs share several structural characteristics:

**Selection:** Champions self-nominate or are nominated by their manager, with security team involvement in final selection. Mandatory appointment produces poor outcomes — champions must be intrinsically motivated.

**Time allocation:** Champions typically receive 10–20% of their time for security champion activities. Without protected time, the role collapses under sprint pressure.

**Enablement:** A recurring training curriculum (monthly or quarterly) addresses the vulnerability classes most relevant to the organization's tech stack. Training is practical, not theoretical — champions should leave each session with something they can apply immediately.

**Community:** A security guild or Slack channel creates peer support between champions across teams. Champions often learn more from each other than from the central security team.

**Recognition:** Security champion contributions should be visible in performance reviews. If the role is invisible to managers and career ladders, attrition is high.

**Escalation paths:** Champions must know exactly when and how to escalate findings to the central security team. Ambiguity about escalation thresholds leads to under-reporting.

---

## Common Failure Modes

- **No time allocation:** Champions deprioritize security work when sprints fill up. Without explicit protected time, the program atrophies.
- **No recognition:** If security champion work is invisible in performance reviews, high-performing engineers will stop doing it.
- **No training:** Champions without updated knowledge make incorrect decisions about what is safe. An untrained champion is worse than no champion — they provide false assurance.
- **Scope creep:** Treating champions as de facto security engineers by assigning them penetration tests, incident response, and policy ownership burns out motivated engineers quickly.

---

## Lab Exercise

The lab for this chapter walks through designing a security champion program for a sample engineering organization:

1. Defining the role charter, scope, and boundaries
2. Creating a candidate selection rubric
3. Building a 90-day onboarding plan for new champions
4. Designing the escalation matrix between champion and central security team
5. Defining success metrics for the program's first year

See [lab/README.md](lab/README.md) to begin.

---

## Further Reading

- [devsecops-methodology: security-champion-program.md](../../../../devsecops-methodology/docs/security-champion-program.md) — full lifecycle model for security champion programs
- [devsecops-methodology: framework.md](../../../../devsecops-methodology/docs/framework.md) — how the security champion role fits into the 4-phase transformation methodology
- [devsecops-methodology: resistance-management.md](../../../../devsecops-methodology/docs/resistance-management.md) — managing engineering team resistance to security integration
