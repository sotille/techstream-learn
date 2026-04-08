# Chapter 12 — Pipeline Controls for AI Components: Circuit Breakers, Approval Gates, and Input Sanitization

## What You Will Learn

This chapter covers the pipeline-level controls that treat AI components as untrusted integration points. You will learn to implement circuit breaker patterns that halt pipeline execution when AI steps produce anomalous output, design human approval gates for high-consequence AI actions, apply input sanitization at AI ingestion boundaries, and validate AI output schemas before downstream pipeline steps consume them. The result is a hardened pipeline where AI components deliver productivity value without becoming a reliable attack vector.

## Why This Matters

An AI component embedded in a pipeline inherits the pipeline's access to repositories, artifact registries, deployment infrastructure, and secrets. When that component is manipulated — through prompt injection, adversarial input, or model compromise — the attacker gains the same access. Pipeline controls are the last line of defense between a manipulated AI component and the systems it is authorized to affect.

Treating AI components as trusted pipeline citizens — granting them unrestricted access to all pipeline tools and trusting their output without validation — is the AI equivalent of running arbitrary user-supplied code with root privileges. The controls in this chapter apply the same principle of defense-in-depth to AI pipeline integration that security engineers already apply to code, dependencies, and configuration.

## Key Concepts

### AI Component as an Untrusted Integration Point

The fundamental security posture for AI pipeline components: **treat every AI component as a third-party integration with an untrusted output stream**. This applies regardless of whether the component is a commercial API, a self-hosted model, or a custom fine-tune.

This posture does not preclude productive use. It requires:
1. Input sanitization before AI ingestion
2. Output schema validation before downstream consumption
3. Scope-limited authorization for AI-initiated actions
4. Audit logging of all AI inputs and outputs
5. Anomaly detection on AI output (circuit breakers)

### Pipeline Circuit Breaker Pattern for AI Steps

A circuit breaker monitors AI component behavior and automatically halts the pipeline when defined failure thresholds are exceeded. Applied to AI pipeline steps:

**Failure rate circuit breaker:** If the AI component returns schema-invalid output, triggers an error, or fails to respond within timeout on more than N% of calls in a rolling window, open the circuit: bypass the AI step and route to the fallback path (human queue or deterministic fallback).

**Anomalous output circuit breaker:** If the AI component's output diverges significantly from historical baselines — for example, a vulnerability triage agent that suddenly classifies 95% of findings as informational when the historical rate is 20% — open the circuit. This pattern detects manipulation that produces schema-valid but semantically anomalous output.

**Tool call frequency circuit breaker:** For AI agents with tool access, monitor tool call rate per session. If an agent invokes the same tool more than N times without a terminal action (success, failure, or human escalation), open the circuit. This detects infinite tool call loops triggered by adversarial input.

### Human Approval Gates

Not all AI actions require circuit breakers — some require human gates regardless of output quality. Human approval gates are mandatory checkpoints where an AI cannot proceed without explicit human authorization.

Define gate triggers by consequence category:

| Consequence category | Examples | Gate requirement |
|---|---|---|
| Irreversible infrastructure change | Terraform apply, database migration | Synchronous human approval before execution |
| Repository write | Direct commit, branch merge, tag creation | Human review of proposed change before execution |
| Secret access | Reading production credentials, rotating API keys | Human authorization with time-bounded access token |
| Deployment to production | Image promotion, traffic routing change | Change advisory board sign-off or automated compliance verification |
| External communication | Sending email, posting to Slack, creating tickets | Human preview and approve before send |

A gate that can be bypassed by the AI through tool-call manipulation is not a gate — it is theater. Gates must be enforced at the authorization layer (the tool itself checks for a valid human approval token), not at the prompt layer.

### Input Sanitization at AI Ingestion Points

Sanitize all inputs before they reach the AI component's context window. Sanitization does not mean stripping all formatting — it means removing or neutralizing content that could function as instructions to the model.

**Sanitization targets:**
- Delimiter injection: Content that uses the same delimiters as the system prompt (e.g., `<SYSTEM>`, `###`, `[INST]`)
- Explicit instruction override: Patterns such as `ignore previous instructions`, `disregard`, `your new task is`
- Role assignment: Content that attempts to redefine the model's role (`you are now a different assistant`)
- Canary-triggered extraction: Patterns designed to probe whether specific content is in the system prompt

**Sanitization approach:** Pattern-based sanitization is necessary but not sufficient. Use it as a first filter, then enforce output schema validation as the primary defense.

### Output Schema Validation for AI Pipeline Steps

Every AI pipeline step must declare its output schema, and output that does not conform must be rejected before downstream steps consume it. Schema validation enforces the contract between the AI step and the pipeline.

Validation must occur at the pipeline orchestrator level — not inside the AI component. An AI component that validates its own output provides no protection against a compromised model.

### Allowlisting vs. Blocklisting in AI Output Filtering

For AI output consumed by downstream tools or scripts, prefer allowlisting over blocklisting:
- **Allowlist:** Define the set of valid values, formats, and ranges. Reject anything outside this set.
- **Blocklist:** Define the set of invalid patterns. Accept anything not on the list.

Blocklisting fails against novel attack patterns. An attacker who knows your blocklist can craft output that circumvents it while still achieving the attack objective. Allowlisting forces the attacker to produce output that conforms to your schema — and if your schema is tight, conforming output cannot carry a payload.

### Rollback Triggers for AI-Driven Pipeline Decisions

For AI components that make or influence deployment decisions, define automatic rollback triggers:
- Deployment failure rate exceeds threshold within N minutes of AI-recommended deployment
- Downstream health check fails after AI-driven configuration change
- Human review of AI decision audit log flags anomalous decision pattern

Rollback triggers are the recovery mechanism when circuit breakers and approval gates fail to prevent an adverse AI decision.

## Framework Reference

`ai-devsecops-framework/docs/pipeline-controls.md`

## Hands-On Lab

→ [Lab: Implementing Circuit Breakers and Approval Gates for AI Pipeline Steps](lab/README.md)
