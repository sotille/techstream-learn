# Chapter 9 — Agent Authorization: The Principle of Least Authority in Agentic Systems

## What You Will Learn

This chapter applies the Principle of Least Authority (POLA) to AI agents operating in DevSecOps pipelines. You will learn why POLA for agents is not the same as traditional IAM least-privilege, how to design and express tool authorization policies, how to implement session-scoped credentials, and how approval gates enforce human oversight for high-consequence actions.

## Why This Matters

When an AI agent is compromised — through prompt injection, context window poisoning, or model manipulation — its blast radius is determined by its authorization scope. An agent with broad permissions can cause widespread harm before the attack is detected. An agent with correctly scoped POLA controls limits the harm to the specific actions that agent was legitimately authorized to take.

Authorization is not a feature to add after agents are deployed. It is an architectural requirement that must be defined before an agent is permitted to take consequential actions. The tool authorization policy is the primary control that separates an agentic system that can be operated safely from one that cannot.

The critical difference between POLA and traditional least-privilege is the enforcement point. Traditional IAM controls restrict which cloud resources an agent can access. POLA for agents also restricts which tools the agent can invoke and under what conditions — even if the underlying cloud resource permissions would technically permit the action. Authorization is enforced at the tool execution layer, not at the LLM.

## Key Concepts

### What Makes Agent Authorization Different

Four properties distinguish agent authorization from standard IAM:

**Tool-level, not resource-level.** An agent authorized to use `github.comment.write` is not authorized to use `github.pr.approve`, even though both operate on GitHub resources. Tool granularity matters because the consequential differences between actions on the same resource can be enormous.

**Session-scoped.** Agent permissions apply to a specific session for a specific task. A remediation agent working on CVE-2024-12345 holds permissions scoped to that session. When the session ends, the credentials expire. Persistent standing permissions are an authorization anti-pattern for agentic systems.

**Non-delegatable upward.** An orchestrating agent cannot grant a subagent more authority than it holds itself. If the orchestrator cannot deploy to production, no subagent it creates can deploy to production, regardless of what the subagent's system prompt claims.

**Execution-layer enforcement.** The authorization policy is enforced by the tool execution layer before any tool call is executed. The LLM deciding to call a tool is not sufficient — the execution layer independently validates the call against the policy. This means prompt injection that causes the LLM to attempt an unauthorized tool invocation results in a blocked call, not an executed one.

### The Tool Authorization Policy Schema

Tool authorization policy is expressed as machine-readable YAML in version control. The YAML policy file defines:
- Which tools each agent role can invoke
- Which operations within each tool are permitted
- Constraints on those operations (scope, rate limits, target restrictions)
- Which actions require human approval before execution
- Session duration limits

See [ai-devsecops-framework/docs/agent-authorization.md](../../../../../ai-devsecops-framework/docs/agent-authorization.md) for the complete policy schema and reference implementations.

### Approval Gates

Not all agent actions should execute automatically. Actions that are irreversible, high blast-radius, or involve privilege are candidates for approval gates — a mechanism that pauses execution and requires explicit human confirmation before proceeding.

The principle for deciding whether an approval gate is required:

> If an adversary who had fully compromised this agent could use this action to cause harm that is difficult or slow to reverse, that action requires an approval gate.

Examples:
- Posting a review comment: no gate required (low blast radius, easily seen and corrected)
- Creating a pull request: gate required (human review of code change before it enters review)
- Merging a pull request: gate required (code change enters main branch; reverting requires follow-on work)
- Deploying to production: gate required with two approvers (high blast radius; difficult to reverse)
- Deleting any resource: gate required (typically irreversible)

## What You Will Practice

This chapter's lab has three exercises:

**Exercise 1** — Read and evaluate an existing tool authorization policy YAML. You will identify at least three authorization gaps and propose specific policy constraints to close them.

**Exercise 2** — Given a scenario where a compromised remediation agent attempts a series of escalating tool invocations, trace which calls would be blocked by the policy and which would succeed. Identify the minimum policy change needed to prevent the successful unauthorized calls.

**Exercise 3** — Design the tool authorization policy for a new agent role: an AI-powered dependency update agent that proposes version updates for outdated dependencies. Define the permitted tools, operations, constraints, session duration, and approval gates. Justify each decision.

## Lab

See [lab/README.md](lab/README.md) for the hands-on exercises.
