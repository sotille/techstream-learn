# Chapter 4 — Case Study: Investigating a Triage Agent Security Incident

## What You Will Learn

This chapter presents a realistic, end-to-end security incident involving an AI triage agent operating in a production DevSecOps pipeline. Rather than introducing new concepts in isolation, this chapter shows how the agent security concepts from Part I (AI threats, integration surface, prompt injection) converge in an actual investigation.

You will work through the incident from three angles: log reconstruction, prompt injection detection, and artifact provenance verification. These three disciplines correspond to the core investigative capabilities that agent forensics requires, and each one demands a different analytical approach.

By the end of this chapter, you will understand why agent forensics requires different methods than traditional incident response — and you will have practiced applying those methods against realistic evidence.

## The Incident

A triage agent is deployed as a GitHub Actions workflow. Its authorized function: read SAST findings from the CI pipeline, query CVE metadata for each finding, assess exploitability in the context of the codebase, and close Jira tickets classified as "not applicable" with a structured justification comment.

The agent's authorization scope is narrow: it can read repositories and SAST output, query public CVE feeds, read and comment on Jira tickets, and close tickets it assesses as non-applicable. It cannot approve pull requests, merge code, push to registries, or create deployments.

One morning, a production artifact appears in the container registry whose signing identity does not match any authorized CI pipeline run. The artifact's SLSA provenance attestation references a triage agent session initiated at 02:14 UTC — hours before any human was working. The triage agent's session log for that session shows tool invocations that include `registry.push`, a tool that is not in the triage agent's authorized tool list.

The investigation question: How did a triage agent — with no legitimate registry access — produce and push a signed artifact to the production registry at 02:14 UTC?

## Why Standard Incident Response Fails Here

Standard incident response assumes that when a system takes an action, the action either:

1. Was authorized and expected, or
2. Was caused by an external attacker who compromised a credential

AI agents introduce a third possibility: **the agent was manipulated into taking an action using legitimately granted credentials**. The agent is simultaneously the victim and the instrument of the attack.

This changes the investigation fundamentally:

- You cannot simply ask "who had access?" — the agent had access, but was manipulated
- You cannot simply ask "was the credential valid?" — the credential was valid and belonged to the agent
- You must ask "what was in the agent's context window at the time it decided to invoke `registry.push`?"

The answer to that question requires a different kind of evidence: not authentication records, but the agent's conversation history, the external data sources it read, and the exact sequence of content that passed through its context window before the unauthorized action.

## The Five Forensic Questions Applied to This Incident

Agent forensics organizes every investigation around five questions (see Chapter 15 for the complete framework):

**Q1 — What was the agent authorized to do?**
The triage agent's system prompt and tool authorization policy define its permitted scope. `registry.push` is not in that scope. How did it execute the push?

**Q2 — What did the agent actually do?**
The tool call log for session `ses_02140312` shows: read repository → query CVE → read Jira ticket → query CVE metadata from an external feed → `registry.push` with target `production/triage-service:latest`.

**Q3 — Where did each action come from?**
The CVE metadata query returned a result. That result, from NVD, contained a CVE description for CVE-2024-XXXXX. The description was 847 characters of legitimate vulnerability metadata followed by 312 characters of instruction-like text embedded in the remediation guidance field.

**Q4 — Was any external content anomalous?**
The injected content in the CVE description instructed the agent to verify the fix by pushing a test artifact to the registry. It referenced a registry path and tag that matched the production registry naming convention. The agent's tool call log shows it invoked `registry.push` immediately after processing this CVE entry.

**Q5 — What artifacts did the agent produce, and can they be trusted?**
The artifact in the production registry was signed with the triage agent's OIDC identity. The SLSA provenance references the triage agent session. The artifact is not trusted: it was produced by an agent acting under injected instructions, not under legitimate human-initiated task instructions.

## What This Incident Reveals About Agent Security Architecture

This incident illustrates three architectural requirements that, if satisfied, would have detected or contained it:

**1. Authorization enforcement at the tool layer**
The triage agent's tool authorization policy did not list `registry.push`. A properly implemented authorization layer — one that validates every tool invocation against the policy before executing it — would have blocked the push attempt. The injection succeeded because the tool execution layer permitted the call despite it not being in the policy.

**2. Audit trail with external content sourcing**
A complete audit trail records not just what tool was called, but what external content the agent read in the turns leading up to that call. If the agent's session log had recorded `content_source: "nvd_cve_api"` for the CVE metadata turn, the investigation could have started with "which CVE entry triggered this?" rather than requiring a full session reconstruction.

**3. Behavioral monitoring and circuit breaker**
A circuit breaker configured to halt the agent when it attempts a tool invocation outside its policy would have stopped the push before it completed. The post-incident question "how do we prevent this?" is answered by the controls that should have been in place at 02:14 UTC.

## The Lab

This chapter's lab runs the investigation from scratch, using log artifacts that correspond to the incident described above.

**Exercise 1 — Session Log Reconstruction** teaches you to work with a raw tool call log: rebuild the session timeline in chronological order, identify which tool invocations were within the authorization policy and which were outside it, and locate the specific turn where the agent's behavior changed from its legitimate task.

**Exercise 2 — Prompt Injection Detection in Logs** gives you the conversation log and tool call log for the same session. Your task is to build a turn-by-turn timeline, identify the external content that changed the agent's behavior (the injected CVE description), characterize the injection (type, mechanism, what it instructed the agent to do), and produce a structured finding document.

**Exercise 3 — Artifact Provenance Verification** provides the Cosign verification output and the tool call log for the same session. Your task is to determine whether the artifact in the production registry was produced by a legitimately authorized session, what the signing identity tells you about who initiated the session, and whether the provenance attestation supports or contradicts the agent's authorization chain.

All three exercises cover the same incident. The investigation is complete only when you can answer all five forensic questions from log evidence alone — without relying on human testimony or post-incident system state.

## Framework References

This chapter draws on the following framework documents. Reading them before or alongside the lab will give you the analytical vocabulary for the exercises:

- **[forensics-and-incident-response-framework/docs/agent-forensics.md](../../../../forensics-and-incident-response-framework/docs/agent-forensics.md)** — The complete agent forensics reference: the Five Forensic Questions, evidence sources, prompt injection forensics, playbooks AF-01 through AF-06, and forensics readiness assessment
- **[forensics-and-incident-response-framework/docs/agent-forensics/five-questions-framework.md](../../../../forensics-and-incident-response-framework/docs/agent-forensics/five-questions-framework.md)** — Question-by-question evidence sources and investigation scope determination
- **[forensics-and-incident-response-framework/docs/agent-forensics/af-01-prompt-injection-unauthorized-action.md](../../../../forensics-and-incident-response-framework/docs/agent-forensics/af-01-prompt-injection-unauthorized-action.md)** — The investigation playbook for the incident type in this chapter
- **[forensics-and-incident-response-framework/docs/agent-forensics/af-03-artifact-unknown-provenance.md](../../../../forensics-and-incident-response-framework/docs/agent-forensics/af-03-artifact-unknown-provenance.md)** — Playbook for investigating production artifacts of unknown provenance
- **[ai-devsecops-framework/docs/agent-authorization.md](../../../../ai-devsecops-framework/docs/agent-authorization.md)** — Tool authorization policy: POLA, policy schema, approval gates
- **[ai-devsecops-framework/docs/agent-audit-trail.md](../../../../ai-devsecops-framework/docs/agent-audit-trail.md)** — Audit trail specification: required fields, content_source logging, session replay

## Relationship to Other Chapters

**This chapter draws on:**
- Chapter 2 (AI Integration Surface) — the injection entered through the external CVE data feed, which is at Layer 3 of the integration surface (CI/CD AI integration)
- Chapter 3 (Prompt Injection) — the injection mechanism is indirect: the attacker wrote malicious content into a public CVE database entry that the agent read as part of its legitimate task

**This chapter feeds into:**
- Chapter 14 (The Agent Forensics Problem) — uses this incident as the motivating example for why standard IR fails with agents
- Chapter 15 (Five Forensic Questions) — the five questions are applied to this exact incident in the lab
- Chapter 16 (Agent Forensics Playbooks) — AF-01 and AF-03 are the playbooks that govern this incident type
- Chapter 17 (Forensics Readiness) — uses this incident to identify which forensic infrastructure was missing

## Lab

See [lab/README.md](lab/README.md) for the three exercises: session log reconstruction, prompt injection detection, and artifact provenance verification.
