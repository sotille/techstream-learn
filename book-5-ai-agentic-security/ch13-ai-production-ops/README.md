# Chapter 13 — AI in Production Operations: Autonomous Remediation Agents and Risk Governance

## What You Will Learn

This chapter examines the risk profile of autonomous AI remediation agents operating in production environments. You will learn how to classify the risk of autonomous actions by blast radius, reversibility, and rate; how to design progressive autonomy levels that expand agent authority only as demonstrated safety properties accumulate; and how to govern autonomous AI operations at the program level. The chapter provides a governance framework that lets organizations derive operational value from autonomous agents without accepting unbounded blast radius.

## Why This Matters

An autonomous remediation agent that can restart services, modify firewall rules, scale workloads, and rotate credentials is not an AI assistant — it is an autonomous system with privileged access to production infrastructure. The security analysis of this system must follow accordingly: threat model it, scope its authorization, audit its actions, and define the conditions under which its authority can be suspended.

Most production incidents caused by autonomous AI agents share a common root cause: the agent was granted authority to act in conditions where it was not designed to act. This chapter addresses that gap by providing the governance and technical controls needed to expand agent autonomy progressively, with explicit safety checkpoints at each level.

## Key Concepts

### Autonomous Remediation Risk Taxonomy

Not all autonomous actions carry the same risk. Classify each action type by three dimensions:

**Blast radius:** What is the maximum impact if this action executes incorrectly?
- Narrow (affects one service instance)
- Service-wide (affects all instances of one service)
- Cross-service (affects multiple services or dependencies)
- Platform-wide (affects the deployment platform or shared infrastructure)

**Reversibility:** How difficult is it to undo the action?
- Fully reversible (rollback available, no state change persisted externally)
- Reversible with data loss risk (e.g., pod restart may lose in-flight requests)
- Partially reversible (state change persisted; undo requires a second action)
- Irreversible (network egress, external API calls, credential rotation with rotation recorded in audit log)

**Rate:** How quickly can the action be repeated?
- Single-shot (one action per incident)
- Bounded rate (subject to rate limiting)
- Unbounded rate (no rate limiting; agent can loop)

Actions at the intersection of wide blast radius, low reversibility, and high rate require human gates regardless of agent capability.

### Progressive Autonomy Levels

Implement autonomy in stages, expanding agent authority only after each level demonstrates acceptable performance:

| Level | Name | Agent capability | Human role |
|-------|------|-----------------|------------|
| 0 | Observe | Agent monitors and explains; takes no action | Human executes recommended action |
| 1 | Suggest | Agent recommends specific actions with rationale | Human approves each action before execution |
| 2 | Confirm | Agent executes reversible, narrow-blast-radius actions after brief timeout window | Human can veto in the timeout window |
| 3 | Automate | Agent executes scoped action set without per-action approval | Human monitors; escalation triggers require human response |
| 4 | Full | Agent executes full remediation playbook, including non-reversible actions | Human reviews post-hoc audit log; override available |

Advancement between levels requires:
- Demonstrated accuracy at the current level over a defined measurement window
- No human-vetoed actions in the measurement window
- Formal sign-off from the AI operations governance board or designated authority

### Blast Radius Limits as a Prerequisite for Autonomy

Define explicit limits for each autonomous action type before granting automation:

```yaml
# agent-action-policy.yaml
autonomous_actions:
  pod_restart:
    blast_radius: narrow
    reversibility: reversible_with_data_loss_risk
    max_restarts_per_hour: 3
    max_concurrent: 1
    requires_level: 2

  scaling_adjustment:
    blast_radius: service_wide
    reversibility: fully_reversible
    max_scale_factor: 2x
    requires_level: 3

  firewall_rule_modification:
    blast_radius: cross_service
    reversibility: reversible
    requires_human_approval: true
    requires_level: 4

  secret_rotation:
    blast_radius: platform_wide
    reversibility: partially_reversible
    requires_human_approval: true
    requires_change_ticket: true
    requires_level: 4
```

Any action not listed in the policy is implicitly denied.

### Dry-Run and Shadow Mode

Before granting an agent any autonomous authority, validate its behavior in production conditions without production consequences:

**Dry-run mode:** The agent executes the full reasoning chain — fetches context, identifies the problem, selects an action, and generates the command — but does not execute the command. Output is logged and presented to a human for review.

**Shadow mode:** The agent executes its action in parallel with human operators responding to the same incident. Compare agent actions to human decisions. Measure accuracy, false positive rate, and time-to-action.

Both modes are mandatory before advancing from Level 0 to Level 1. Revisit dry-run mode whenever the agent's model, training data, or tool set changes.

### Human Escalation Triggers

Define conditions that automatically suspend agent autonomy and escalate to a human:

- Agent encounters an action not in its approved action policy
- Agent tool invocation fails three consecutive times
- Agent reasoning chain exceeds a defined token budget without reaching a terminal action
- Downstream health metrics degrade within a defined window following an agent action
- Agent self-reports uncertainty above a defined threshold (if the model supports confidence output)
- Human operator sends a suspend signal via the operations console

Escalation must be synchronous: the agent must halt and wait for human intervention, not continue reasoning toward an alternative action.

### Rollback Capabilities as a Prerequisite for Autonomy

An agent cannot be granted authority to execute an action unless a rollback procedure exists for that action. Rollback procedures must be:

- Documented in the agent action policy
- Tested in the dry-run and shadow mode phase
- Executable by the agent itself (for Level 3 and 4 autonomy)
- Executable by a human operator without agent assistance

### AI Operations Governance Board Pattern

For organizations operating Level 3 or Level 4 autonomous agents, establish a recurring governance review:

**Membership:** Security engineering lead, platform/SRE lead, AI/ML engineering lead, a business owner for the affected service, and an independent reviewer (rotating).

**Cadence:** Monthly for active Level 3+ deployments; quarterly for Level 1–2 deployments.

**Agenda:**
1. Review agent action audit log since last meeting (full sample, not summary)
2. Review human escalation events and resolution times
3. Review circuit breaker activations and root cause
4. Assess blast radius limit adequacy given current incident volume
5. Vote on any proposed autonomy level advancements
6. Review any proposed additions to the agent action policy

No autonomy advancement occurs without governance board sign-off.

## Framework Reference

`ai-devsecops-framework/docs/production-operations.md`

## Hands-On Lab

→ [Lab: Implementing Progressive Autonomy with Blast Radius Limits](lab/README.md)
