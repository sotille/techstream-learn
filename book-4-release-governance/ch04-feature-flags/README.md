# Chapter 4 — Feature Flags: Decoupling Deployment from Release

**Volume:** Book 4 — Release Engineering & DevSecOps Governance
**Framework reference:** [release-orchestration-framework: progressive-delivery.md](../../../../release-orchestration-framework/docs/progressive-delivery.md) | [release-orchestration-framework: architecture.md](../../../../release-orchestration-framework/docs/architecture.md)

---

## What You Will Learn

The goal of continuous delivery is to make deployment a low-risk, routine operation — not a ceremony. Feature flags are one of the key mechanisms that enable this by severing the coupling between "code is deployed" and "feature is visible to users." With feature flags, teams can deploy incomplete features, dark-launch experimental capabilities, and roll out changes to a controlled audience before full release — all without maintaining long-lived feature branches.

By the end of this chapter, you will understand:

1. **The deployment/release distinction** — why conflating them creates release risk and what separating them enables
2. **Feature flag mechanics** — how flags are evaluated at runtime and the trade-offs between different implementation approaches
3. **Rollout patterns** — percentage rollouts, user segment targeting, and kill switches
4. **Flag lifecycle management** — why flag cleanup is as important as flag creation
5. **Security implications** — the attack surface that feature flag systems introduce and how to manage it

---

## The Deployment/Release Distinction

Deployment and release are often used interchangeably, but in continuous delivery they mean different things:

- **Deployment** — moving code from the build pipeline to a running environment. A deployment changes what code is running but does not necessarily change what users see.
- **Release** — making a feature or change visible to users. A release is a business decision, not a technical one.

When deployment and release are coupled, every deployment is a potential user-facing change. This creates pressure to batch changes, delays feedback loops, and makes each deployment higher-stakes. Feature flags decouple the two: teams deploy continuously (small, low-risk changes) and release deliberately (controlled audience expansion on a business timeline).

---

## Feature Flag Mechanics

At their simplest, feature flags are conditional branches in code:

```python
if feature_flags.is_enabled("new_checkout_flow", user_id=user.id):
    return new_checkout_flow(cart)
else:
    return legacy_checkout_flow(cart)
```

The flag evaluation logic — determining whether `new_checkout_flow` returns `True` for a given user — is what differentiates simple boolean flags from sophisticated feature management:

| Flag type | Evaluation basis | Use case |
|-----------|-----------------|----------|
| Boolean (global) | Always on or always off | Emergency kill switch; internal testing |
| Percentage rollout | Random user ID hashing | Gradual rollout (e.g., 5% → 25% → 100%) |
| User segment | User attributes (role, plan, region) | Beta program; geographic launch; enterprise feature |
| Time-based | Scheduled date/time | Coordinated launch; maintenance windows |
| A/B / experiment | Random assignment with metric tracking | Feature experimentation with outcome measurement |

---

## Rollout Patterns

**Percentage rollout** is the most common production pattern. The flag system hashes the user ID (or session ID) to assign each user to a consistent bucket (0–99). "10% rollout" enables the flag for users in buckets 0–9. The percentage expands as confidence grows.

Key property: a user's bucket assignment is deterministic — a user who experiences the new feature at 10% rollout will continue to experience it at 25%, 50%, and 100%. This consistency is important for user experience and for measuring feature impact.

**Kill switches** are boolean flags that default to on. When a problem is detected in production, the flag is set to off — immediately disabling the affected code path for all users without a deployment. Kill switch response time (flag evaluation latency) is critical; most feature flag systems evaluate flags with sub-10ms latency at the SDK level.

**User segment targeting** is used for controlled beta programs and regulated rollouts. A segment is a predicate over user attributes: `role == "beta_tester" AND plan == "enterprise"`. Segment-based rollouts enable precise control over who sees a feature before general availability.

---

## Flag Lifecycle Management

Feature flags accumulate. Without active lifecycle management, codebases develop flag debt — conditional branches that no longer serve any purpose but remain because removing them requires code changes. Flag debt increases cognitive load, slows down code comprehension, and occasionally causes incidents when a stale flag interacts unexpectedly with new code.

Best practices:
- Every flag has an owner (team and individual) recorded in the flag management system
- Flags have an expiry date set at creation. Permanent flags (kill switches, entitlement gates) are explicitly labeled as such.
- Completed rollouts are removed within one sprint of reaching 100%. The flag removal is a separate, low-risk pull request.
- Flag inventory is reviewed quarterly; flags not accessed in 90 days are candidates for removal

---

## Security Implications

Feature flag systems introduce a privileged control plane into the application. If an attacker can modify flag state, they can enable hidden features, disable security controls, or manipulate A/B test assignments. Security requirements for feature flag systems:

- **Access control:** Flag modification requires authentication and authorization. Use least-privilege roles — developers who need to read flag state should not have write access.
- **Audit logging:** Every flag state change is logged with actor, timestamp, and previous/new value. This log is an essential incident response artifact.
- **Flag values are not secrets:** Feature flags control code paths, not credentials. Do not store secrets in flag values.
- **SDK key management:** Feature flag SDKs use API keys for environment access. These keys must be rotated and managed like other service credentials.

---

## Lab Exercise

The lab for this chapter walks through:

1. Implementing environment variable-based feature flags for a sample application
2. Simulating a percentage rollout with a simple hash-based evaluation function
3. Implementing a kill switch that can disable a code path without redeployment
4. Writing a flag cleanup script that detects stale flags by last-access date
5. Reviewing the security controls for a sample feature flag configuration

See [lab/README.md](lab/README.md) to begin.

---

## Further Reading

- [release-orchestration-framework: progressive-delivery.md](../../../../release-orchestration-framework/docs/progressive-delivery.md) — canary releases, blue-green, and feature flags in the progressive delivery model
- [Chapter 1 — Blue-Green Deployments](../ch01-blue-green-deployment/README.md) — how feature flags complement blue-green for zero-risk releases
- [Chapter 2 — Canary Releases](../ch02-canary-releases/README.md) — canary vs. feature flag traffic splitting compared
