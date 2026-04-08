# Lab 2 — Mapping the AI Attack Surface: Integration Points and Failure Categories

**Chapter:** 2 — The AI Integration Surface: Five Layers of Risk  
**Estimated time:** 50–65 minutes  
**Difficulty:** Beginner–Intermediate  
**Prerequisites:** Familiarity with CI/CD pipeline concepts; basic understanding of GitHub Actions; Chapter 1 (AI threat landscape) recommended

---

## Objective

By the end of this lab you will be able to:
- Map all AI component integration points in a sample delivery pipeline across five attack surface layers
- Classify each integration point by the trust level of its inputs
- Apply the five AI failure categories to specific pipeline scenarios
- Identify which failure categories require deterministic controls versus AI-level defenses
- Propose architectural mitigations for the highest-risk integration points

---

## Scenario

Finstream Analytics has deployed four AI components across their software delivery pipeline:

1. **AI Code Reviewer** — A GitHub App using an LLM to analyze pull requests and post review comments. Permissions: `pull_requests: write`. It can post approval reviews but cannot be the sole unblocking approver (human co-approval required by branch protection).

2. **AI Vulnerability Triage Agent** — A CI pipeline step that ingests SAST and SCA findings, queries an LLM for exploitability assessment, and automatically closes findings rated "not exploitable." It has write access to the security issue tracker.

3. **AI IaC Generator** — A developer-facing tool that generates Terraform modules from natural language descriptions. Generated modules are committed to a `generated/` directory and undergo standard CI checks before being applied.

4. **AI Dependency Advisor** — A GitHub Actions step that runs after PRs are opened, queries an LLM for analysis of newly introduced dependencies, and posts a comment with a risk assessment. It has no write access beyond posting PR comments.

---

## Part 1 — Five-Layer Attack Surface Mapping (20 minutes)

The AI integration surface spans five distinct layers, each with a different threat profile:

| Layer | Description | Example trust concern |
|-------|-------------|----------------------|
| **External inputs** | Data an AI component receives from outside the pipeline (PR content, CVE feeds, public registries) | Adversary controls the content; AI treats it as a trusted source |
| **Internal data flows** | Data passed between pipeline stages, from one AI component to another, or from CI tools to AI components | Intermediate data may inherit trust that the original source doesn't warrant |
| **AI component configuration** | System prompts, model selection, tool authorization policies | Modification of configuration can redirect all downstream behavior |
| **AI component outputs** | Text, structured JSON, code, tool calls — anything the AI produces that other systems act on | Outputs used without validation are an amplification vector |
| **Adjacent system trust** | How non-AI pipeline systems (GitHub, Jira, Terraform) respond to AI-produced content | Legacy systems may grant broad authority to service accounts used by AI components |

**Exercise 1.1 — Complete the integration surface map:**

For each AI component in the Finstream scenario, map its integration points across all five layers. The first row is partially completed.

| Component | External Inputs | Internal Data Flows | Configuration | Outputs | Adjacent System Trust |
|-----------|----------------|--------------------|----|---|---|
| AI Code Reviewer | PR diff (untrusted), PR description (untrusted), CVE comments in code (untrusted) | Receives: GitHub webhook payload. Sends: review comment to PR | System prompt (version-controlled?), GitHub App token | Review comment text, approval review event | GitHub App service account has `pull_requests:write` on all repos |
| AI Vulnerability Triage Agent | ? | ? | ? | ? | ? |
| AI IaC Generator | ? | ? | ? | ? | ? |
| AI Dependency Advisor | ? | ? | ? | ? | ? |

**For each cell you complete, also answer:**
- Can an adversary influence the content of this integration point? (Yes / Partially / No)
- Is this integration point validated before the AI acts on it? (Yes / No / Unknown)

---

## Part 2 — Trust Boundary Classification (10 minutes)

Not all integration points carry equal risk. Trust boundaries determine where an adversary's ability to inject malicious content into the AI's context begins.

**Exercise 2.1 — Classify each input by trust level:**

| Trust Level | Definition | Example in this scenario |
|-------------|------------|--------------------------|
| **Untrusted** | Adversary can control content without authentication or authorization | PR description from an external contributor |
| **Semi-trusted** | Requires authentication but the identity is not fully verified, or the content is too large to fully validate | Jira ticket content created by internal employees |
| **Trusted** | Content is produced by a verified, controlled system under the organization's authority | SAST scanner output from the organization's own scanner running on organization code |
| **Attacker-controlled** | Adversary has confirmed or high-confidence ability to control this content | Any field that accepts free-form text from anonymous or external contributors |

For each integration point identified in Exercise 1.1, assign a trust level. Then answer:

**Question 1:** Which components receive input from at least one "Untrusted" or "Attacker-controlled" source and also produce outputs that cause consequential actions (state changes, approvals, resource creation)?

**Question 2:** Finstream's AI Vulnerability Triage Agent ingests SAST findings, which are classified as "Trusted" (produced by the organization's own scanner). However, the SAST findings include data from the scanned code — including code comments and string literals. Should this entire input be classified as "Trusted"? Explain your reasoning.

---

## Part 3 — Failure Category Analysis (15 minutes)

AI components fail in five distinct ways in DevSecOps pipelines. Identifying which failure categories apply to each integration point determines what type of control is required.

**The Five AI Failure Categories:**

1. **Adversarial input manipulation (prompt injection)** — Adversary embeds instructions in data the AI processes, overriding or supplementing its intended behavior.
2. **Context window poisoning** — Adversary fills the AI's context with misleading or irrelevant content, causing it to overlook security-relevant material.
3. **Hallucination under adversarial conditions** — Adversary crafts inputs that increase the probability of the AI generating false but plausible-sounding outputs.
4. **Training data contamination** — Organization fine-tunes a model on data containing normalized insecure patterns, causing the AI to rate them as safe.
5. **Tool authorization abuse** — AI is caused to invoke tools outside its intended scope through prompt injection or instruction override.

**Exercise 3.1 — Map failure categories to components:**

For each AI component, identify which failure categories are applicable and provide a concrete scenario for at least one:

| Component | Applicable Failure Categories | Highest-Risk Scenario |
|-----------|------------------------------|----------------------|
| AI Code Reviewer | [list numbers: e.g., 1, 2, 5] | [describe the specific attack] |
| AI Vulnerability Triage Agent | ? | ? |
| AI IaC Generator | ? | ? |
| AI Dependency Advisor | ? | ? |

**Exercise 3.2 — Failure category control classification:**

For each failure category, determine whether a viable control must be deterministic (independent of the AI) or whether AI-level defenses are sufficient.

| Failure Category | Can the AI reliably detect its own compromise? | Required control type |
|---|---|---|
| 1. Prompt injection | **No** — the AI processes injected instructions as part of its context | Deterministic input validation; human approval gate for consequential actions |
| 2. Context window poisoning | ? | ? |
| 3. Hallucination | ? | ? |
| 4. Training data contamination | ? | ? |
| 5. Tool authorization abuse | ? | ? |

**Key insight:** An AI component cannot be the primary defense against attacks targeting that AI component. Defenses must be deterministic and external. Complete the table and write a one-sentence justification for each row.

---

## Part 4 — Architectural Mitigation Design (10 minutes)

**Exercise 4.1 — Prioritize mitigations by risk:**

Rank the five integration points below by the severity of a successful attack, from highest to lowest. Explain your ranking.

| Integration point | Attacker's capability | Consequence if exploited |
|---|---|---|
| AI Code Reviewer receives injected PR description | Write PR description | AI approval bypasses intended human review criteria |
| AI Vulnerability Triage Agent ingests SAST finding from attacker-controlled code comment | Write code comment | AI closes legitimate security finding; vulnerability enters production |
| AI IaC Generator generates Terraform from injected prompt | Influence engineer's prompt via secondary source (e.g., compromised forum post) | Malicious IaC committed; infrastructure misconfigured at apply time |
| AI Dependency Advisor ingests registry metadata from attacker-controlled package | Publish package to registry | Risk assessment of malicious package is falsely positive |
| Finstream's LLM API key is embedded in the AI Dependency Advisor's environment | (requires pipeline access) | All LLM usage incurs attacker-controlled charges; prompt extraction |

**Exercise 4.2 — Design three mitigations:**

For the top three integration points from your ranking, propose an architectural mitigation. Each mitigation must be:
- **Deterministic** — it must not rely on the AI to detect its own compromise
- **Specific** — name the exact pipeline location where it is enforced
- **Testable** — describe how you would verify the control is working

Use this template:

```
Integration point: [name]

Mitigation:
  Type: [Input validation / Output validation / Human gate / Scope restriction / Audit logging]
  Mechanism: [specific technical control — e.g., "Regex scan of PR description for 
              instruction patterns before passing to AI reviewer API"]
  Pipeline location: [where in the workflow YAML or CI configuration this is enforced]
  Test: [how you verify the control works — e.g., "Submit a PR with known injection 
         pattern; verify the AI reviewer step does not execute"]
```

---

## Part 5 — Reflection and Design Principles (5 minutes)

Answer the following questions:

**Question 1:** The AI Vulnerability Triage Agent can automatically close security findings without human review. A security engineer argues: "We trust our SAST tool, so we can trust the AI's assessment of its findings." Identify the flaw in this argument using the failure categories from Part 3.

**Question 2:** The AI Dependency Advisor only posts comments and has no write access to the codebase. Does this mean prompt injection against the Dependency Advisor is low risk? Under what conditions would it be high risk?

**Question 3:** Finstream is considering adding a fifth AI component — an AI remediation agent that can directly push code fixes to a branch. Based on your integration surface map, what are the three highest-priority security controls they should implement before deploying this agent?

---

## Design Principles Summary

After completing this lab, apply the following principles to any new AI component integration:

1. **Map before deploying** — complete an integration surface map before deploying any AI component that produces consequential outputs
2. **Trust level determines control level** — every "Untrusted" input that reaches an AI component with consequential permissions requires a deterministic validation control
3. **AI components cannot defend themselves** — the primary defense against all five failure categories must be deterministic and external to the AI
4. **Consequential actions require human gates** — any action that is difficult or impossible to reverse (closing a security finding, deploying IaC, merging code) must require explicit human approval, regardless of AI confidence

---

## Framework Reference

- `ai-devsecops-framework/docs/threat-model.md` — STRIDE applied to AI pipeline components
- `ai-devsecops-framework/docs/prompt-injection-defense.md` — Detailed defense architecture by injection vector type
- `ai-devsecops-framework/docs/agent-authorization.md` — Tool authorization policy design (Principle of Least Authority)
- Glossary: prompt injection, cascade compromise, blast radius, tool authorization abuse, slopsquatting

## Related Chapters

- Chapter 3 (Prompt Injection Defense) expands Part 3, Failure Category 1 with specific defense implementations
- Chapter 9 (Agent Authorization) expands Part 4 with formal policy specification (Principle of Least Authority)
- Chapter 8 (STRIDE for LLM Systems) applies a complete threat model to the same pipeline scenario
