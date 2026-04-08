# Lab 5 — AI Security Maturity Self-Assessment

**Estimated time:** 40–55 minutes
**Difficulty:** Beginner–Intermediate
**Prerequisites:** Familiarity with DevSecOps concepts and CI/CD pipelines

---

## Objective

By the end of this lab you will be able to:
- Apply the five-level AI security maturity model to a realistic organization scenario
- Identify which maturity checklist items are satisfied versus open for a given organization
- Produce a prioritized 90-day roadmap to advance to the next maturity level

---

## Scenario

Finova is a 350-person fintech company with 40 engineers. They have been using AI tools in their development workflow for approximately 18 months. Here is what is true of their current posture:

**AI tools in use:**
- GitHub Copilot for all engineers (IDE integration)
- An LLM-powered PR review bot deployed via GitHub Actions (posts security review comments, cannot approve or merge)
- A third-party AI vulnerability triage service integrated into their Jira workflow (ingests SAST findings, posts triage analysis comments on Jira tickets, has write access to Jira; can close tickets rated "not applicable")
- Developers individually using ChatGPT and Claude.ai (not organization-managed)

**What they have done:**
- Maintained a list of "approved AI tools" in their internal wiki (last updated 6 months ago; the vulnerability triage service is not on it)
- Extended their Gitleaks configuration with OpenAI API key patterns; this runs in CI
- The PR review bot uses a dedicated GitHub App with minimal permissions (read PR, write PR comment — no merge or approve)
- No explicit AI acceptable use policy has been published; engineers follow general code of conduct

**What they have not done:**
- No secrets detection as a pre-commit hook (CI only)
- No dependency confusion detection in their SCA tool (they use Snyk, which supports it but it is not configured)
- No input sanitization on data passed to the AI vulnerability triage service (it receives raw SAST findings, including content from scanned code)
- No output validation on the triage service's output before it updates Jira tickets
- No prompt canary tokens in any AI component
- No tool authorization policy document; permissions are set informally
- No audit log of AI agent actions
- No approval gate before the triage service closes Jira tickets
- No inventory of which models are in use in the triage service or the PR bot (both are SaaS tools)

---

## Exercise 1 — Maturity Assessment (25 minutes)

Apply the maturity checklist from the reference below to Finova's scenario. For each checklist item, mark it as:
- **SATISFIED** — evidence in the scenario shows this is done
- **PARTIAL** — partially done but not fully meeting the criterion
- **NOT SATISFIED** — not done or no evidence of it

Then determine Finova's current maturity level.

### Level 1 Checklist

| Item | Status | Evidence or Gap |
|------|--------|----------------|
| AI tool inventory exists and is current (< 30 days old) | ? | ? |
| AI acceptable use policy published and distributed | ? | ? |
| Secrets detection with AI provider key patterns (pre-commit hook AND CI gate) | ? | ? |
| SCA configured with dependency confusion detection | ? | ? |
| AI pipeline components do not have production deployment access without approval | ? | ? |
| AI pipeline components use dedicated service accounts, not shared credentials | ? | ? |

### Level 2 Checklist

| Item | Status | Evidence or Gap |
|------|--------|----------------|
| Data source maps completed for all AI pipeline components | ? | ? |
| Input sanitization deployed for all AI pipeline component inputs | ? | ? |
| All LLM API integrations use `system` role for instructions, `user` role for data | ? | ? |
| Output schema validation deployed for all structured AI outputs | ? | ? |
| Prompt canary tokens deployed in all AI pipeline component system prompts | ? | ? |
| Behavioral baselines established; anomaly alerting active | ? | ? |
| Adversarial test suite run for all AI pipeline components | ? | ? |

### Level 3 Checklist

| Item | Status | Evidence or Gap |
|------|--------|----------------|
| Tool authorization policy YAML in version control for all agent roles | ? | ? |
| Tool authorization enforced at execution layer (not just LLM config) | ? | ? |
| Human approval gates for all irreversible agent actions | ? | ? |
| Immutable audit log deployed; agent cannot write to its own log | ? | ? |
| System prompts in version control; SHA in session audit records | ? | ? |
| Session-scoped credentials; persistent standing tokens eliminated | ? | ? |
| Self-modification prohibition verified for all agents | ? | ? |

### Level 4 Checklist

| Item | Status | Evidence or Gap |
|------|--------|----------------|
| Red-team exercises targeting AI pipeline components conducted at least annually | ? | ? |
| AI component behavioral baselines reviewed and recalibrated after every model version update | ? | ? |
| Forensics readiness score ≥ Level 3 (audit infrastructure able to answer all Five Forensic Questions) | ? | ? |
| Blast radius limits enforced at infrastructure level (network policies, IAM session duration caps) | ? | ? |
| Multi-agent systems have input validation at every inter-agent boundary | ? | ? |
| AI pipeline incidents have a dedicated runbook (adapted from Five Forensic Questions Framework) | ? | ? |
| Tool authorization policies in version control; changes require security team review | ? | ? |

### Level 5 Checklist

| Item | Status | Evidence or Gap |
|------|--------|----------------|
| Continuous adversarial testing of AI components integrated into the CI pipeline (automated red-team on every build) | ? | ? |
| AI security posture metrics reported to executive leadership on a monthly cadence | ? | ? |
| Forensics readiness score = Level 5 (full session replay from immutable audit store) | ? | ? |
| Model supply chain integrity verified on every model update (digest verification, Cosign signing, ModelScan) | ? | ? |
| ISO 42001 certification achieved or formal assessment completed | ? | ? |
| AI security improvements are systematically fed back into the AI component training/fine-tuning process | ? | ? |

**Question 1:** What is Finova's current maturity level? Support your answer with specific references to the checklist results.

**Question 2:** Identify the two highest-risk open items at Finova's current level (the items where the absence of the control is most likely to result in a real security incident). Explain why these are the highest-risk gaps.

**Question 3:** Finova's AI vulnerability triage service can close Jira tickets without human approval. Identify which maturity level this gap belongs to and explain the specific threat it exposes Finova to.

**Question 4:** A Finova engineer argues: "We're a 350-person startup — Level 3 is good enough for us." Using the scenario details, identify one specific condition under which Finova's current Level 1 gaps create a material risk that cannot be deferred.

---

## Scoring Guidance

When checklist items are PARTIAL, apply the following rule: **a PARTIAL on any item in the current level counts as NOT SATISFIED for the purpose of level determination.** A level is achieved only when all items are SATISFIED.

This means:
- An organization that satisfies 5 of 6 Level 1 items and all Level 2 items is still at Level 1
- The roadmap should prioritize closing the PARTIAL/NOT SATISFIED items at the current level before advancing

Exception: If an organization satisfies all items at Level N but has one PARTIAL at Level N+1, they may be described as "Level N with partial Level N+1 posture."

---

## Exercise 2 — 90-Day Maturity Roadmap (25 minutes)

Produce a 90-day roadmap to advance Finova from their current maturity level to the next level. Structure the roadmap in three 30-day phases.

For each item in the roadmap, include:
- The checklist item it closes
- The specific implementation action required
- The team responsible (Security, Platform, or All Engineers)
- The success criterion (how you verify the control is working, not just deployed)
- Dependencies (if any)

Use the following template:

```
## Phase 1 (Days 1–30): Foundation Gaps

### Item: [checklist item name]
- Implementation: [specific action]
- Owner: [team]
- Success criterion: [verifiable outcome]
- Dependencies: [none / other items]

[repeat for each Phase 1 item]

## Phase 2 (Days 31–60): [theme]
[...]

## Phase 3 (Days 61–90): [theme]
[...]
```

**Prioritization guidance:**
- Phase 1 should address the two highest-risk gaps you identified in Exercise 1, plus any items with no dependencies
- Phase 2 should address items that require Phase 1 deliverables or that require more effort
- Phase 3 should address verification activities and items that depend on Phase 2

**Question:** After the 90-day roadmap is complete, what would be Finova's new maturity level? Are there any checklist items that would still be incomplete, and if so, why are they deferred beyond 90 days?

---

## Reference

- [ai-devsecops-framework/docs/roadmap.md](../../../../../ai-devsecops-framework/docs/roadmap.md) — Five-level AI security maturity roadmap with complete checklists
- [ai-devsecops-framework/docs/agent-authorization.md](../../../../../ai-devsecops-framework/docs/agent-authorization.md) — Tool authorization policy implementation reference
- [ai-devsecops-framework/docs/prompt-injection-defense.md](../../../../../ai-devsecops-framework/docs/prompt-injection-defense.md) — Prompt injection controls for Level 2
- Glossary: AI security maturity model, tool authorization policy, approval gate, prompt canary, behavioral baseline
