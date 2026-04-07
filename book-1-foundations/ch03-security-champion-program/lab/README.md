# Lab 3 — Designing a Security Champion Program

**Estimated time:** 45–60 minutes
**Difficulty:** Beginner–Intermediate
**Format:** Document-based design exercise (no code required)
**Prerequisites:** None — this lab works for practitioners at any technical level

---

## Overview

This lab guides you through designing a security champion program for a fictional engineering organization. You will produce a program charter that can be adapted for your own organization.

The fictional organization context:
- **Company:** Acme Financial Services
- **Engineering headcount:** 120 engineers across 12 product teams
- **Security team:** 3 security engineers (1 AppSec, 1 CloudSec, 1 GRC)
- **Current state:** No formal security champion program. Security reviews happen ad hoc and are consistently late-stage.
- **Primary compliance requirement:** SOC 2 Type II — requires evidence of security training and access control review processes

---

## Part 1: Define the Role Charter (15 minutes)

Using the template in `examples/role-charter-template.md`, define the security champion role for Acme Financial Services.

Your charter must address:

1. **Role definition** — In 2–3 sentences, what does a security champion do at Acme?
2. **Scope boundaries** — List three things that ARE in scope and three things that are NOT in scope for this role
3. **Time allocation** — How many hours per week / percentage of time will champions dedicate to this role?
4. **Reporting relationship** — Does the champion report to their engineering manager, to the security team, or have a dual structure?
5. **Selection criteria** — List 4–5 characteristics or behaviors that predict success in this role at Acme

---

## Part 2: Design the Onboarding Plan (15 minutes)

Using `examples/onboarding-plan-template.md`, design a 90-day onboarding plan for a new security champion.

**Month 1 — Orientation:**
- What training will new champions complete in their first month?
- Who are they introduced to in the security team?
- What is their first concrete deliverable?

**Month 2 — First Ownership:**
- What is the first security responsibility the champion takes on independently?
- What check-ins happen between champion and security team?

**Month 3 — Integration:**
- How is the champion integrated into the security guild?
- What does the end-of-90-day assessment look like?

---

## Part 3: Define the Escalation Matrix (10 minutes)

Security champions must know when to handle issues themselves vs. when to escalate. Design an escalation matrix for Acme using `examples/escalation-matrix-template.md`.

For each of the following finding types, specify: **Handle independently**, **Escalate to security team**, or **Escalate + page on-call**:

| Finding | Recommended Action |
|---------|-------------------|
| Dependency with CVSS 5.2 (Medium), no known exploit | Handle independently |
| Hardcoded AWS key found in a feature branch (not yet merged) | |
| Hardcoded AWS key found in the main branch (deployed to prod) | |
| Authentication bypass in a non-production endpoint | |
| Authentication bypass in a production payment endpoint | |
| SAST finding: SQL injection in a read-only reporting query | |
| SAST finding: SQL injection in a write endpoint with PII | |
| Dependency with CVSS 9.8 (Critical), public exploit available | |

Fill in the blank cells using the escalation criteria from the [devsecops-methodology: security-champion-program.md](../../../../../devsecops-methodology/docs/security-champion-program.md) framework.

---

## Part 4: Define Success Metrics (10 minutes)

Complete the metrics table in `examples/program-metrics-template.md` with targets for Acme's first year.

For each metric category, define:
- The metric name and unit
- The baseline (current state, even if unknown/zero)
- The 6-month target
- The 12-month target
- The data source

Metric categories to cover:
1. Champion coverage (% of teams with an active champion)
2. Training completion (% of champions who completed quarterly training)
3. Early detection rate (% of security findings caught before production)
4. Escalation quality (% of escalations that result in confirmed findings)
5. Champion retention (% of champions still active after 12 months)

---

## Reflection Questions

1. The Acme security team is skeptical about the champion program because "developers can't do real security work." What argument — backed by the framework content — would you make to address this objection?

2. Engineering managers at Acme are concerned that the 15% time allocation will slow down delivery. How do you quantify the trade-off? What data from the DevSecOps ROI model supports the investment?

3. After six months, three of Acme's eight security champions have stopped participating. What are the most likely causes, and what structural changes would you make to the program?

---

## Deliverables

By the end of this lab, you should have:
- [ ] Completed role charter (Part 1)
- [ ] 90-day onboarding plan (Part 2)
- [ ] Escalation matrix (Part 3)
- [ ] Program metrics with 12-month targets (Part 4)

These documents, adapted to your organization, constitute the foundational artifacts for launching a security champion program.
