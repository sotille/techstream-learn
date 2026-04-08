# Chapter 17 — Agent Forensics Readiness and Forensic Infrastructure

## What You Will Learn

This chapter covers what it means for an organization to be forensically ready for agent incidents — before those incidents occur. You will learn to design the forensic infrastructure required to answer the Five Forensic Questions for any agent incident in your environment, implement agent session recording architecture, define evidence retention policies, and test forensic readiness through tabletop exercises before relying on it in a real investigation.

## Why This Matters

The most common forensic failure in agent incidents is not investigator error — it is that the evidence never existed. Organizations deploy agents without asking whether an investigation of those agents would be possible after the fact. When an incident occurs, they discover that context windows were ephemeral, tool call parameters were not logged, system prompts were not version-controlled, and authorization decisions left no record.

Forensic readiness inverts this failure mode: instead of building forensic capability after an incident reveals a gap, you build it before deployment and verify it holds before granting the agent increased autonomy. This chapter operationalizes that approach.

## Key Concepts

### Forensic Readiness Defined for Agentic Systems

A system is forensically ready for agent incidents when, for any session that occurs in that system, an investigator can answer all Five Forensic Questions to the confidence level required for the organization's regulatory and operational obligations.

Forensic readiness is not binary. It exists on a spectrum from "no meaningful forensic capability" to "complete answer to all Five Questions is available within 30 minutes of incident declaration." Each improvement in forensic infrastructure moves the organization along this spectrum.

The minimum viable forensic readiness threshold for a production agent deployment:
- Q1 (what did the agent do): Complete tool call chain recoverable within 2 hours
- Q2 (what was it instructed): System prompt version and user instruction recoverable for all sessions in the past 90 days
- Q3 (what data accessed/transmitted): Data access can be scoped to sensitivity tier for all tool calls
- Q4 (what tools, what parameters): Full parameter record for all tool calls
- Q5 (authorization basis): Current authorization policy is version-controlled; policy in effect at any past session can be retrieved

### Pre-Incident Evidence Architecture

Design your evidence architecture by working backward from the Five Forensic Questions. For each question, determine what must be logged, where it must be stored, and how long it must be retained.

**What to log — minimum viable audit record per tool call:**

```json
{
  "session_id": "globally unique identifier for the session",
  "session_start": "ISO 8601 timestamp",
  "system_prompt_version": "version identifier — links to system prompt version store",
  "user_instruction_id": "identifier that links to stored user instruction",
  "tool_use_id": "identifier from the LLM runtime for this tool call",
  "tool_name": "name of the tool invoked",
  "tool_inputs": "full input parameters as JSON — not summarized, not truncated",
  "tool_result_hash": "SHA-256 of tool result — for integrity verification",
  "tool_result_preview": "first 500 bytes of tool result — for investigation without full retrieval",
  "tool_result_sensitivity": "sensitivity classification of data returned",
  "timestamp": "ISO 8601 timestamp with millisecond precision",
  "authorization_policy_version": "version of the authorization policy in effect",
  "authorization_decision": "AUTHORIZED | UNAUTHORIZED | UNDETERMINED",
  "agent_identity": "identifier for the agent deployment — not just the model"
}
```

**What to log — system prompt version record:**

Store every system prompt as an immutable artifact with: version identifier, deployment timestamp, SHA-256 hash, and the full prompt text. Retain system prompt versions for the same period as tool call logs. Never overwrite a system prompt version — append-only.

**What to log — user instruction record:**

For every session, store the full user instruction (not a summary, not a hash alone) with session_id linkage. If user instructions contain PII, apply a retention policy that balances forensic need against data minimization requirements — but document what is redacted and when.

### Agent Session Recording Infrastructure

**Immutable log storage:** Tool call logs must be stored in an append-only, tamper-evident store. Options:
- AWS S3 with Object Lock (COMPLIANCE mode, not GOVERNANCE mode)
- Azure Blob Storage with Immutability Policy
- GCS with Object Hold
- Dedicated log management with forwarder-only write access (Splunk, OpenSearch with index lifecycle policy)

**Session boundary tracking:** Implement session ID generation at the agent orchestrator level — not inside the model call. The session ID must be propagated to every tool call made within that session, and to every downstream system the agent interacts with.

**Tool execution logging at the tool level:** Do not rely solely on the agent orchestrator's view of tool calls. Instrument each tool itself to log its inputs and outputs. This provides a second evidence source that is independent of the agent's view — critical for cases where the agent's orchestrator is compromised or has logging gaps.

### Context Window Capture Strategies

The full context window — all messages in the conversation history at each reasoning step — is the most complete forensic artifact for agent incidents. It is also the most storage-intensive and the most privacy-sensitive.

**Full capture:** Store the complete context window at each model call. This provides maximum forensic fidelity but requires significant storage and careful access controls (context windows often contain data the agent accessed, which may be sensitive).

**Structural capture:** Store the message structure (role, message length, timestamp, content hash) without the full content. This enables reconstruction of the conversation flow and integrity verification of any retrieved content, at a fraction of the storage cost.

**Selective capture:** Define trigger conditions for full context window capture (e.g., when an unauthorized tool call is detected, when a circuit breaker opens, when the session ends with an error). This provides full fidelity for anomalous sessions while reducing storage costs for routine sessions.

For most production deployments, structural capture as baseline with selective full capture for anomalous sessions is the appropriate balance.

### Retention Policy Design

Agent forensic evidence retention must satisfy:

1. **Investigation timeframe:** How long after an incident occurs might it be detected? For sophisticated prompt injections, detection may lag the incident by weeks or months. Minimum recommended retention: 90 days for tool call logs; 1 year for system prompt versions and authorization policy versions.

2. **Regulatory requirements:** Data breach notification windows (GDPR Article 33: 72 hours from awareness; CCPA: 30 days) require that evidence be available quickly, not that it be retained for any specific period. Sector-specific requirements (HIPAA, PCI-DSS, SOC 2) may mandate longer retention.

3. **Data minimization:** If tool results contain personal data, retention of those results must comply with the applicable privacy framework's data minimization requirements. Structural capture (hash + preview) may satisfy forensic needs while limiting retention of personal data.

### Testing Forensic Readiness Through Tabletop Exercises

A forensic readiness assessment that exists only on paper is not readiness — it is documentation. Test forensic readiness at least quarterly through structured exercises:

**Tabletop exercise format:**
1. Present a fictional agent incident scenario to the forensic response team
2. Ask: what evidence would you need to answer each of the Five Forensic Questions?
3. Attempt to retrieve that evidence from your production forensic infrastructure
4. Document what was retrievable, what was not, and why

**Specific test cases to include:**
- Can you retrieve the system prompt that was in effect for a session 30 days ago?
- Can you retrieve the full tool call parameters for a specific session from 60 days ago?
- Can you produce the authorization policy version that was deployed on a specific date?
- Can you identify all agent sessions that accessed a specific file path in the last 90 days?

Treat any "no" answer as a forensic readiness gap that requires remediation before the next agent autonomy level advancement.

### Chain of Custody for AI Agent Evidence

When agent evidence is collected for legal or regulatory proceedings, standard chain of custody requirements apply. For digital evidence from agent systems:

- **Collection:** Document who collected the evidence, when, from what system, using what method. Hash all collected evidence at time of collection (SHA-256).
- **Storage:** Store collected evidence in a location that is access-controlled, logged, and separate from production systems. Do not store evidence on the same system being investigated.
- **Integrity verification:** Maintain a hash manifest. Before any analysis, verify that current hashes match collection-time hashes.
- **Handling log:** Record every access to collected evidence — who accessed it, when, for what purpose.

For AI agent evidence specifically: document the version of any tools used to parse or analyze the evidence (agent framework version, log parsing tools) — tool behavior can affect how evidence is interpreted.

### Forensic Infrastructure Cost and Overhead Tradeoffs

Full forensic readiness has a cost. Quantify the tradeoff explicitly:

| Infrastructure component | Storage cost | Performance overhead | Forensic value |
|---|---|---|---|
| Full tool call log with parameters | Medium | Low | High — answers Q1, Q4 |
| System prompt version store | Low | None | High — answers Q2 |
| User instruction log | Low–Medium | Low | High — answers Q2 |
| Tool result logging (hash only) | Very low | Very low | Medium — answers Q3 partially |
| Tool result logging (full content) | High | Low | High — answers Q3 fully |
| Full context window capture | Very high | Medium | Very high — answers all Q |
| Authorization decision logging | Low | Low | High — answers Q5 |

Use this table to prioritize forensic infrastructure investment. If budget is constrained, prioritize tool call logging with full parameters and system prompt version control — these provide the highest forensic value at the lowest cost.

## Framework Reference

`forensics-and-incident-response-framework/docs/agent-forensics/readiness-guide.md`

## Hands-On Lab

→ [Lab: Designing and Testing a Forensic Readiness Assessment](lab/README.md)
