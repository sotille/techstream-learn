# Lab — EU AI Act and NIST AI RMF Control Mapping

**Chapter:** 19 — The Regulatory Landscape for AI in Software Delivery
**Estimated time:** 45–60 minutes
**Difficulty:** Beginner–Intermediate
**Prerequisites:** Familiarity with DevSecOps concepts; completion of Ch. 8 (STRIDE) and Ch. 9 (agent authorization) helpful

---

## Objective

Map the AI components in a representative DevSecOps organization to their EU AI Act risk tier, identify the compliance requirements that apply, and cross-reference each requirement to the Techstream framework controls that satisfy it. Produce a one-page compliance gap analysis.

---

## Scenario

You are the security engineer for a mid-sized software organization. Your team has deployed the following AI components in the software delivery pipeline:

1. **Copilot-style coding assistant** integrated into developer IDEs (GitHub Copilot)
2. **AI-powered code review agent** that posts security findings to pull requests
3. **AI vulnerability triage agent** that ranks SAST findings by severity and actionability
4. **AI remediation agent** (pilot) that proposes code changes for low-severity findings and creates GitHub issues for high-severity findings
5. **AI test generation tool** that proposes unit tests for new code

Your organization operates in the EU and is subject to the EU AI Act.

---

## Part 1 — EU AI Act Classification

**Exercise 1.1 — Classify each AI component:**

For each component, determine its EU AI Act risk tier. Use the classification framework from Chapter 19.

| AI Component | Your classification | Reasoning |
|---|---|---|
| IDE coding assistant (Copilot) | | |
| AI code review agent | | |
| AI vulnerability triage agent | | |
| AI remediation agent | | |
| AI test generation tool | | |

**Guidance questions:**
- Does the component "interact with humans" in a way that triggers Article 50 transparency obligations?
- Does the component make decisions about work assignment, prioritization, or management of engineering tasks that could qualify it as a worker-management AI under Annex III?
- Does the component take actions with direct impact on production systems?

**Reference answer** (attempt your own before reviewing):

| AI Component | Classification | Reasoning |
|---|---|---|
| IDE coding assistant | Minimal risk | Suggests code; engineer makes all decisions; no automated action |
| AI code review agent | Limited risk (Art. 50) | Interacts with engineers via PR comments; disclosure required |
| AI vulnerability triage agent | Minimal risk | Internal prioritization tool; does not interact with users directly |
| AI remediation agent | Limited risk (Art. 50) + possible high-risk review | Creates issues (limited risk disclosure); if it modifies work queues or manages engineering tasks at scale, high-risk assessment warranted |
| AI test generation tool | Minimal risk | Proposes tests; engineer makes all decisions; no automated action |

---

## Part 2 — Compliance Requirements by Component

**Exercise 2.1 — Identify compliance requirements:**

For each component classified as Limited Risk or above in Exercise 1.1, list the applicable EU AI Act requirements.

**AI code review agent:**

| Requirement | Article | Applies? | Notes |
|---|---|---|---|
| Transparency disclosure (AI-generated content) | Art. 50 | Yes | Must disclose that findings are AI-generated in each PR comment |
| Risk management system | Art. 9 | No | High-risk only |
| Technical documentation | Art. 11 | No | High-risk only |
| Automatic logging | Art. 12 | Recommended | Not mandatory for limited risk; best practice |
| Human oversight | Art. 14 | Recommended | Not mandatory; best practice |

**AI remediation agent (if high-risk):**

| Requirement | Article | Applies? | Notes |
|---|---|---|---|
| Risk management system | Art. 9 | Yes | Document identified risks and mitigations |
| Data governance | Art. 10 | Yes | Document training data sources, quality controls |
| Technical documentation | Art. 11 | Yes | Architecture, model card, intended use |
| Automatic logging | Art. 12 | Yes | Log every agent decision and action |
| Human oversight | Art. 14 | Yes | Human must be able to override or stop the agent |
| Accuracy and cybersecurity | Art. 15 | Yes | Adversarial robustness testing; pipeline controls |

---

## Part 3 — Control Mapping

**Exercise 3.1 — Map requirements to Techstream controls:**

Complete the control mapping table for the AI remediation agent (assumed high-risk):

| EU AI Act Requirement | Techstream Control | Implementation Location | Gap? |
|---|---|---|---|
| Risk management system (Art. 9) | STRIDE threat model for LLM systems | ai-devsecops-framework/docs/threat-modeling.md | |
| Data governance (Art. 10) | | | |
| Technical documentation (Art. 11) | | | |
| Automatic logging (Art. 12) | | | |
| Human oversight (Art. 14) | | | |
| Cybersecurity (Art. 15) | | | |

Use the control mapping tables from Chapter 19 to fill in the Techstream control and implementation location. Mark "Gap" if no Techstream control currently addresses the requirement.

**Reference answer:**

| EU AI Act Requirement | Techstream Control | Implementation Location | Gap? |
|---|---|---|---|
| Risk management system (Art. 9) | STRIDE-LLM threat model | Ch. 8; ai-devsecops-framework/docs/threat-modeling.md | No |
| Data governance (Art. 10) | Agent authorization policy; data handling policy | Ch. 9; ai-devsecops-framework/docs/agent-authorization.md | Partial — training data documentation not addressed |
| Technical documentation (Art. 11) | Framework documentation + model card | ai-devsecops-framework README | Partial — model card format not standardized |
| Automatic logging (Art. 12) | Immutable agent audit trail | Ch. 10; ai-devsecops-framework/docs/agent-audit-trail.md | No |
| Human oversight (Art. 14) | Human approval gates | Ch. 12; ai-devsecops-framework/docs/pipeline-controls.md | No |
| Cybersecurity (Art. 15) | Output schema validation; circuit breakers; model supply chain | Ch. 7, 12 | No |

---

## Part 4 — NIST AI RMF Mapping

**Exercise 4.1 — Map NIST AI RMF sub-categories:**

For three NIST AI RMF sub-categories of your choice, document the specific DevSecOps implementation that satisfies the requirement.

Format:
```
NIST AI RMF Sub-category: [ID and name]
Requirement: [what the sub-category requires]
DevSecOps implementation: [specific control or document]
Evidence: [what artifact proves the control exists]
Maturity indicator: [how would you know if this is working well?]
```

**Example:**
```
NIST AI RMF Sub-category: MANAGE 1.3 — Risk treatments implemented and documented
Requirement: Responses to identified AI risks are selected and enacted
DevSecOps implementation: Pipeline controls (circuit breakers, approval gates, output validation)
  implemented per ai-devsecops-framework/docs/pipeline-controls.md
Evidence: Pipeline configuration files; circuit breaker alert history; approval gate audit log
Maturity indicator: <1% of AI pipeline step runs trigger circuit breaker; 100% of high-consequence
  AI actions have a corresponding approval record in the audit log
```

Complete three entries using different NIST AI RMF functions (GOVERN, MAP, MEASURE, MANAGE).

---

## Part 5 — Gap Analysis and Remediation Plan

**Exercise 5.1 — Produce a compliance gap analysis:**

Based on Exercises 1–4, produce a one-page gap analysis in the following format:

```
Organization: [name]
Assessment date: 2026-04-07
AI components reviewed: 5 (see Exercise 1.1)
Regulatory frameworks applied: EU AI Act, NIST AI RMF, OWASP LLM Top 10

COMPLIANT (controls in place):
- [list items with framework reference]

PARTIAL GAP (controls exist but incomplete):
- [list items with description of gap and remediation action]

OPEN GAP (no control currently addresses requirement):
- [list items with proposed remediation and owner]

Recommended immediate actions (next 30 days):
1. [highest priority action]
2.
3.

Recommended 90-day actions:
1.
2.
3.
```

---

## Reflection Questions

1. The EU AI Act has staggered compliance dates: prohibited AI provisions applied February 2025; general-purpose AI model provisions applied August 2025; high-risk system requirements apply August 2026. If your organization's AI remediation agent is high-risk, what is the compliance deadline, and what would a realistic implementation roadmap look like?

2. NIST AI RMF is a voluntary framework in the United States. Under what conditions might a US-based DevSecOps team be effectively required to implement NIST AI RMF controls despite their voluntary status?

3. The OWASP LLM Top 10 is maintained by a community and updated periodically. LLM01 (Prompt Injection) has been the top-ranked risk since the list's inception. What would have to change in the AI security landscape for a different category to claim the top position? What would that mean for your pipeline control priorities?

---

## Framework Reference

`ai-devsecops-framework/docs/regulatory-mapping.md`

## Learning Checkpoint

After completing this lab you should be able to:
- Classify AI components in a DevSecOps pipeline under the EU AI Act risk tiers
- Identify the compliance requirements that apply to limited-risk and high-risk AI systems
- Map EU AI Act and NIST AI RMF requirements to Techstream framework controls
- Produce a compliance gap analysis that prioritizes remediation actions by regulatory deadline and risk
