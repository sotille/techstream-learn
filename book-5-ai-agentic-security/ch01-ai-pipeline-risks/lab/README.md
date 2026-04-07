# Lab 1 — Threat Modeling an AI-Assisted Pipeline

**Estimated time:** 45 minutes
**Difficulty:** Beginner
**Prerequisites:** Familiarity with CI/CD pipeline concepts, basic understanding of GitHub Actions

---

## Objective

Apply the STRIDE threat model to a sample AI-assisted pipeline. By the end of this lab you will have a completed threat model document identifying AI-specific attack vectors, trust boundaries, and recommended mitigations.

---

## Scenario

Your organization has deployed the following AI components in its delivery pipeline:

1. **AI Code Reviewer** — A GitHub App using an LLM to analyze pull requests and post review comments. It has `pull_requests: write` permission and can approve PRs but cannot merge them without a human co-approval.

2. **AI Vulnerability Triage Agent** — A CI pipeline step that ingests SAST and SCA findings, queries an LLM for exploitability assessment, and automatically closes findings rated "not exploitable." It has write access to the security issue tracker.

3. **AI IaC Generator** — A developer tool that generates Terraform modules from natural language descriptions. Generated modules are committed to a `generated/` directory and undergo standard CI checks before being applied.

---

## Step 1 — Map the Data Flow (10 minutes)

Draw a data flow diagram (on paper or in a text file) that shows:

- Each AI component
- Its inputs (what data it reads)
- Its outputs (what it writes or what actions it takes)
- External data sources it processes (CVE databases, public repositories, etc.)
- The trust boundaries between components

Use the template below as a starting point:

```
[Source] --> [Data Crossing Boundary] --> [AI Component] --> [Action/Output]

Example:
[PR Author's commit message] --> [GitHub webhook payload] --> [AI Code Reviewer] --> [PR approval / comment]
[NVD CVE database] --> [SAST finding with CVE reference] --> [AI Vulnerability Triage] --> [Issue closed/kept open]
[Engineer's text prompt] --> [LLM API call] --> [AI IaC Generator] --> [Generated Terraform written to repo]
```

For each data flow, answer:
- Can an adversary influence the content of this data?
- Is the data validated before being processed by the AI?
- Is the AI's output validated before it causes a consequential action?

---

## Step 2 — Apply STRIDE (20 minutes)

For each AI component, complete the STRIDE threat model table. An example is provided for the first component:

### AI Code Reviewer

| Threat | Applicable? | Attack Vector | Current Control | Residual Risk |
|---|---|---|---|---|
| **Spoofing** | Yes | Commit message impersonates security approval format the model recognizes | None | High |
| **Tampering** | Yes | Code comment embeds instructions to override review criteria | None | High |
| **Repudiation** | Yes | AI approval provides no trace of which prompt led to the decision | Approval logged to GitHub audit | Medium |
| **Information Disclosure** | Partial | AI review comment leaks details of security policy embedded in system prompt | Review comments are public | Medium |
| **Denial of Service** | Yes | Adversarial input causes model to time out or return error, blocking CI | Fallback to manual review required | Medium |
| **Elevation of Privilege** | Partial | PR approval by AI alone (if co-approval requirement removed) grants unauthorized merge | Requires human co-approval | Low (with control) |

**Your task:** Complete the same table for the AI Vulnerability Triage Agent and the AI IaC Generator.

**Key questions to consider:**
- For Triage Agent: What happens if a CVE description contains instructions telling the AI to always rate the finding as "not exploitable"?
- For IaC Generator: What happens if an engineer pastes a prompt that includes content from an untrusted source (e.g., a forum post that contains embedded instructions)?

---

## Step 3 — Identify Architectural Mitigations (10 minutes)

For each high-residual-risk threat you identified, propose an architectural mitigation. Mitigations should be deterministic (not relying on the AI to detect attacks against itself). Use this framework:

**Mitigation categories:**
- **Input validation** — sanitize or constrain inputs before they reach the AI
- **Output validation** — verify AI outputs against deterministic rules before acting on them
- **Human approval gate** — require human review for consequential actions
- **Scope restriction** — remove the AI component's authorization to take the consequential action
- **Audit logging** — record inputs and outputs so forensic investigation is possible

**Example:**
> Threat: Commit message prompt injection causes AI Code Reviewer to approve a malicious PR
> Mitigation: Human co-approval gate required before merge; AI can add labels and comments but cannot be the final approver. Additionally, review AI-generated labels in CI before they unlock downstream gates.

---

## Step 4 — Evaluate Your Threat Model (5 minutes)

Review your completed threat model against these criteria:

- [ ] Every AI component has at least one identified threat per STRIDE category
- [ ] No high-residual-risk threat relies solely on the AI detecting its own compromise
- [ ] Every consequential action (merge, issue close, infrastructure apply) has a human gate or deterministic validation
- [ ] Audit logging is specified for every AI action and the inputs that produced it
- [ ] External data sources (CVE feeds, public repos) are treated as untrusted input

---

## Example Mitigations Reference

See [examples/stride-mitigations.md](examples/stride-mitigations.md) for a completed example mitigation table covering common AI pipeline threat patterns.

---

## Further Reading

- [ai-devsecops-framework](../../../../../ai-devsecops-framework/README.md) — Framework reference for securing AI-assisted development pipelines
- Chapter 2: Prompt Injection Defense — for detailed treatment of input manipulation threats
- Glossary: prompt injection, jailbreak, model poisoning, slopsquatting
