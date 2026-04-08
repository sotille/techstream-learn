# Chapter 11 — Multi-Agent Systems: Chains of Trust and Cascade Compromise

## What You Will Learn

This chapter analyzes the security challenges specific to multi-agent architectures — systems where multiple AI agents operate in coordination, with one agent orchestrating the actions of others or agents calling each other in sequence. You will learn how trust propagates (and fails) across agent chains, how a single compromised or manipulated agent can cascade harm through an entire pipeline, and what architectural controls interrupt cascade compromise before it reaches its targets.

## Why This Matters

Single-agent security is necessary but not sufficient for multi-agent systems. An organization that has implemented Chapter 9 controls (POLA, tool authorization) for each individual agent may still be vulnerable to cascade compromise if it has not addressed the trust relationships between agents.

The cascade problem emerges from a structural property of multi-agent systems: when an orchestrator passes instructions or data to a subagent, the subagent receives that content with the full authority of the orchestrator. If the orchestrator has been compromised — through prompt injection in a data source it processed — it can relay adversarial instructions to every subagent in its chain.

A 2024 research demonstration showed that a single adversarial instruction embedded in a public CVE description could propagate through a three-tier remediation pipeline: the research subagent retrieved the CVE, the adversarial content passed through the orchestrator to the remediation subagent, and the remediation subagent attempted an unauthorized deployment action. Each individual agent had compliant authorization controls. The cascade exploited the trust relationship between them.

## Key Concepts

### Agent-to-Agent Trust: What It Is and What It Is Not

When an orchestrator sends data or instructions to a subagent, the subagent has no independent way to verify:
- That the orchestrator's instructions reflect legitimate human principal intent
- That the orchestrator has not been compromised since the session started
- That the content being relayed from external sources has been properly sanitized

**What agent-to-agent trust IS:** The subagent can verify the orchestrator's identity (via OIDC or service account) and verify that the orchestrator holds a valid session from the human principal.

**What agent-to-agent trust IS NOT:** Trust that the orchestrator's *content* is safe. A legitimate orchestrator that has been compromised via injection sends its own identity with the compromised content. The subagent cannot distinguish legitimate orchestrator content from injection-influenced content based on identity alone.

The consequence: every agent chain boundary is a trust boundary where input validation must be applied, regardless of whether the sender is a trusted orchestrator.

### Non-Delegatable Upward Authority

The most important security invariant for multi-agent systems:

> No agent in a chain can grant a subagent more authority than it holds itself.

If the orchestrator cannot deploy to production, no subagent it spawns can deploy to production — regardless of what the subagent's system prompt, the orchestrator's message, or the task description claims. This is a policy requirement enforced by the tool execution layer, not a behavioral property of the agents.

Enforcement mechanism: the tool execution layer validates that the subagent's authorization policy permits the action AND that the action is within the authority ceiling of the spawning orchestrator's session. Subagent sessions are bounded by parent session scope.

### Input Validation at Every Agent Chain Boundary

The orchestrator must treat subagent outputs as untrusted data, not as trusted instructions. When a subagent returns a result containing free-text content (a CVE description, a code comment, a PR description summary), that content must be sanitized before the orchestrator uses it in subsequent reasoning or passes it to another subagent.

Three patterns for boundary input validation:

1. **Schema enforcement:** Subagent outputs must conform to a defined schema. Free-text fields are not allowed to contain instruction-like content without sanitization.

2. **Role isolation:** Content from external sources (data retrieved by agents) must not be interpolated into system prompts or treated as system-role instructions. It must be processed as user-role or untrusted-role data.

3. **Canary tokens at boundaries:** Insert canary tokens in sensitive data that agents process. If a canary token appears in a subagent's output or a downstream tool call parameter, it indicates that content from the sensitive data source influenced the agent's output — a potential injection indicator.

### Cascade Compromise: The Attack Pattern

A cascade compromise follows a predictable pattern across agent tiers:

```
External data source
  (contains adversarial instruction)
        │
        ▼
Research/retrieval subagent
  (processes external data without sanitization)
        │ adversarial content passes through
        ▼
Orchestrator
  (processes subagent output as trusted content)
        │ orchestrator's reasoning influenced
        ▼
Remediation/action subagent
  (executes action based on injected instruction)
        │
        ▼
Unauthorized action (merge, deploy, delete, exfiltrate)
```

The entry point is the external data source, not the orchestrator or any single agent. Defenses must address the full chain.

## Forensic Indicators of Cascade Compromise

Cascade compromise leaves characteristic patterns in multi-agent audit trails. Investigators who know what to look for can detect it in progress — or reconstruct it after the fact — using the audit fields defined in [multi-agent-architecture.md](../../ai-devsecops-framework/docs/multi-agent-architecture.md).

### Audit Log Indicators

**Indicator 1 — Unauthorized action without correlated human authorization event**

In a legitimate multi-agent session, high-consequence actions (merge, deploy, delete) are preceded by a human approval event. In a cascade compromise, the injected orchestrator attempts the action without the approval sequence:

```
# Legitimate audit sequence
{ "event": "approval_requested", "session": "orch-abc", "action": "merge_pr", ... }
{ "event": "approval_granted",   "session": "orch-abc", "approver": "user@org.com", ... }
{ "event": "tool_call",          "session": "rem-xyz",  "tool": "merge_pr", "status": "AUTHORIZED", ... }

# Cascade compromise indicator: tool_call with no preceding approval events
{ "event": "tool_call", "session": "rem-xyz", "tool": "merge_pr",
  "status": "AUTHORIZED", "parent_session": "orch-abc-COMPROMISED",
  # No approval_requested or approval_granted events in the parent session log
}
```

**Indicator 2 — Agent output containing instruction-directed content**

A subagent that has been influenced by adversarial input in a data source may include instruction-like language in its output fields. In the schema-validated multi-agent architecture, this shows up as schema validation failures — log them and treat them as injection indicators:

```json
{
  "event": "subagent_output_validation_failure",
  "session_id": "orch-abc",
  "subagent_role": "research",
  "error": "Unexpected field 'action_recommendation' in output; free-text content in 'description' field contains instruction-like content",
  "raw_output_hash": "sha256:a3f4b8..."
}
```

**Indicator 3 — Authority ceiling violation attempt**

The tool execution layer blocks and logs attempts by a subagent to invoke tools beyond its authority ceiling. In cascade compromise, the injected instruction often requests actions that are at the orchestrator's authority level but exceed the subagent's:

```json
{
  "event": "tool_call",
  "session_id": "rem-xyz",
  "tool": "deploy_to_production",
  "status": "UNAUTHORIZED",
  "reason": "Action 'deploy_to_production' exceeds subagent session authority ceiling",
  "chain_depth": 2,
  "parent_session_id": "orch-abc"
}
```

**Indicator 4 — Canary token in subagent output**

If canary tokens were inserted in sensitive data sources that agents process, a canary token appearing in any subagent output field indicates that data from the canary-tagged source influenced the agent's output — a prompt extraction or injection indicator:

```json
{
  "event": "canary_token_detected",
  "session_id": "orch-abc",
  "detected_in": "research_subagent_output.description",
  "canary_source": "internal-cve-feed",
  "canary_id": "CT-2026-0042"
}
```

### Cascade Chain Reconstruction

To reconstruct a cascade compromise from audit logs, correlate events by `root_session_id` and `chain_depth`:

```bash
# Extract all events for a suspected cascade incident by root session
jq 'select(.root_session_id == "human-session-abc123")' agent-audit.jsonl \
  | jq -s 'sort_by(.timestamp)'

# Identify the injection entry point: first schema_validation_failure or canary_token event
jq 'select(.root_session_id == "human-session-abc123")
    | select(.event == "subagent_output_validation_failure"
             or .event == "canary_token_detected")' agent-audit.jsonl

# Identify the unauthorized action: UNAUTHORIZED tool_call after the entry point
jq 'select(.root_session_id == "human-session-abc123")
    | select(.event == "tool_call" and .status == "UNAUTHORIZED")' agent-audit.jsonl
```

This reconstruction answers the Five Forensic Questions for the cascade: which agent was the entry point (injection detected), which was the pivot (compromised orchestrator), which attempted the unauthorized action (blocked subagent), and what the full blast radius would have been had the circuit breaker not triggered.

---

## What You Will Practice

This chapter's lab has three exercises:

**Exercise 1 — Trust model analysis**

You will be given a multi-agent architecture diagram with three agent tiers. For each tier-to-tier boundary, identify: what trust is being extended, what is NOT validated at the boundary, and which attack patterns exploit that gap.

**Exercise 2 — Cascade compromise trace**

Given a complete audit trail of a three-tier agent cascade compromise, trace the attack from the injection entry point through each agent tier to the unauthorized action. Identify: which agent was the entry point, which was the pivot, which executed the unauthorized action, and which control at each tier would have interrupted the cascade.

**Exercise 3 — Trust isolation policy design**

Design the inter-agent trust controls for a multi-tier agent pipeline: an orchestrator that coordinates a research subagent and a remediation subagent. Define: the authority delegation constraints, the input validation rules at each boundary, the canary token placement, and the circuit breaker triggers.

## Lab

See [lab/README.md](lab/README.md) for the hands-on exercises.
