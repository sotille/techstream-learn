# Chapter 10 — Agent Audit Trails: Immutable Logging and Session Replay

## What You Will Learn

This chapter defines the minimum viable audit record for an AI agent action and describes the architecture for an immutable agent audit trail that supports forensic investigation, compliance evidence, and real-time anomaly detection. You will learn what must be logged (and what logging is insufficient), how to implement tamper-resistant append-only storage for agent audit events, and how to use the audit trail to reconstruct an agent session for forensic review.

## Why This Matters

Agent authorization controls (Chapter 9) define what agents are permitted to do. Agent audit trails record what agents actually did. These are complementary controls — neither is sufficient alone.

Without an authorization policy, agents can take unauthorized actions. Without an audit trail, unauthorized actions go undetected, uninvestigated, and unremediated.

The audit trail is also the foundation for the Five Forensic Questions framework (Chapter 15). An organization with agents operating in production but without an adequate audit trail cannot investigate agent incidents. This is not a theoretical limitation — in practice, organizations that have deployed agents without audit trails have been unable to determine:

- Whether a suspicious action was performed by the agent or a human using the agent's service account
- What data was in the agent's context window when it took a disputed action
- Whether a given agent action was within its authorized scope
- How a multi-agent chain arrived at a specific outcome

The audit trail is the difference between an investigable incident and an uninvestigable one.

## Key Concepts

### The Minimum Viable Audit Record

Every agent tool call must produce an audit record with the following fields. These are the minimum — omitting any field creates an investigation gap.

| Field | Description | Why Required |
|---|---|---|
| `session_id` | Unique identifier for the agent session | Correlates all events in a session; needed for session replay |
| `agent_role` | The agent role (not the model name — the organizational role) | Identifies which tool authorization policy applies |
| `human_principal` | Identity of the human who initiated the session | Chain of accountability from human to agent action |
| `task_description` | Description of the task the session was initialized to perform | Defines the legitimate scope; needed for Q2 |
| `tool_name` | The tool that was called | Core of the action record |
| `input_parameters` | Full parameters passed to the tool call | Needed for forensic scope analysis (Q3, Q4) |
| `authorization_status` | Whether the call was permitted or blocked | Needed for Q5 and policy compliance verification |
| `authorization_policy_version` | Commit hash of the policy in effect | Needed to evaluate policy compliance at incident time (Q5) |
| `system_prompt_version` | Commit hash of the system prompt in effect | Needed to establish what the agent was instructed to do (Q2) |
| `timestamp` | ISO 8601 timestamp with millisecond precision | Sequence reconstruction and correlation |
| `root_session_id` | Session ID of the human principal's session | For multi-agent chains: links all subagent events to the root |

### Why "Log the Tool Call" Is Insufficient

Organizations that deploy agents with basic logging often log the tool call — the tool name and timestamp. This produces an incomplete record that cannot answer most of the Five Forensic Questions:

| What basic logging captures | What basic logging misses |
|---|---|
| Which tools were called | What parameters were passed (Q4) |
| When they were called | What the agent was instructed to do (Q2) |
| That the call happened | Whether it was authorized (Q5) |
| — | What data was accessed or transmitted (Q3) |
| — | The full session context (Q2) |

### Append-Only Storage: Why It Matters

The audit trail for a compromised agent must not be writable by the agent. An agent that has been compromised through prompt injection may be caused to delete or modify its own audit records. The audit store must be in a separate infrastructure environment from the agent runtime, with write access only to the specific append operation (no delete, no overwrite).

Implementations:
- **AWS:** S3 with Object Lock in COMPLIANCE mode (prevents deletion during the lock period)
- **GCP:** Cloud Storage with retention policy and locked bucket
- **Kubernetes:** Audit events written to a separate namespace that the agent's service account cannot read or delete

### Session Replay

A session replay reconstructs the inputs and actions of an agent session for forensic review. Replay does not re-execute the agent (which would produce non-deterministic results). It reconstructs the *evidence record*: what instructions the agent received, what tools it called with what parameters, and what results those tools returned — allowing investigators to trace how the agent's context evolved and identify where adversarial content entered.

## What You Will Practice

This chapter's lab has three exercises:

**Exercise 1 — Audit record completeness evaluation**

You will review audit records from three agent sessions. For each session, identify which of the minimum viable audit record fields are present, which are missing, and which of the Five Forensic Questions cannot be answered due to the missing fields.

**Exercise 2 — Audit trail architecture design**

Given a scenario description of an agent deployment (agent type, cloud environment, existing logging infrastructure), design the append-only audit trail architecture. Specify the storage technology, write access control, retention policy, and query interface.

**Exercise 3 — Session replay from audit trail**

Given a partial audit trail for a suspected-compromise incident, reconstruct the session timeline. Identify the point in the session where the agent's behavior deviated from its legitimate task scope, and identify the most likely injection source based on the tool results that preceded the deviation.

## Lab

See [lab/README.md](lab/README.md) for the hands-on exercises.
