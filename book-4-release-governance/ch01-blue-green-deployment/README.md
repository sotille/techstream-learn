# Chapter 1 — Blue-Green Deployments: Reducing Release Risk with Traffic Switching

**Volume:** Book 4 — Release Engineering & DevSecOps Governance
**Framework reference:** [release-orchestration-framework](../../../../release-orchestration-framework/docs/progressive-delivery.md) | [release-orchestration-framework: gitops-architecture.md](../../../../release-orchestration-framework/docs/gitops-architecture.md)

---

## What You Will Learn

Deployment failures have two distinct failure modes. The first is a deployment that fails during rollout — the application does not start, health checks fail, and the rollout controller halts. Most deployment platforms handle this automatically with rollback. The second failure mode is more dangerous: a deployment that succeeds technically but delivers broken behavior — degraded performance, subtle logic errors, or features that only fail under certain conditions. By the time monitoring detects the problem, thousands of users have been affected.

Blue-green deployment is a release strategy that eliminates exposure to the second failure mode by keeping the previous version running and directing traffic only after the new version is confirmed healthy.

This chapter covers:

1. **Blue-green deployment mechanics** — how traffic switching works and why it differs from rolling deployments
2. **Kubernetes implementation** — using Services and Ingress for traffic switching
3. **Automated verification** — smoke tests and health gates between switch and cutover
4. **Rollback engineering** — switching back in under 30 seconds
5. **Coordination with compliance** — change management evidence from blue-green deployments

---

## Why Deployment Strategy Is a Security and Governance Decision

Release strategy is often treated as a purely operational concern. It is not. The deployment strategy determines:

- **Blast radius**: How many users are exposed to a defective release before it is detected and rolled back
- **Rollback capability**: Whether recovery requires a new deployment (minutes) or a traffic switch (seconds)
- **Audit trail**: Whether each release can produce evidence of the exact artifact deployed, when, by whom, and how traffic was switched
- **Change management compliance**: SOX, PCI-DSS, and internal change management policies require documented, reproducible, reversible change procedures. Blue-green deployments with automation are inherently auditable; manual deployments are not.

---

## Blue-Green vs. Rolling vs. Canary

| Strategy | Description | Blast Radius | Rollback Time | Complexity |
|----------|-------------|-------------|---------------|------------|
| Rolling | Replace instances incrementally; old and new run simultaneously during rollout | Proportional to rollout speed | Minutes (new rollout) | Low |
| Blue-green | Two identical environments; switch traffic atomically after verification | Zero (switch is instantaneous) | Seconds (switch back) | Medium |
| Canary | Route a small percentage of traffic to the new version; expand on success | Controlled (percentage-based) | Seconds (route to 0%) | High |

Blue-green is the right choice when:
- Instantaneous rollback is a hard requirement (financial systems, payments, regulated services)
- Database schema changes must be coordinated with application version (see also: expand/contract migration pattern)
- Change management requires a pre-verified state before any customer traffic

---

## Blue-Green Mechanics in Kubernetes

In Kubernetes, blue-green is implemented using the Service abstraction:

```
                        ┌─────────────────────────────┐
                        │  Kubernetes Service          │
                        │  selector: version=blue ──── │──► Blue Pods (v1.0)
                        │                              │     (currently active)
                        │  (switch: version=green) ─── │──► Green Pods (v1.1)
                        └─────────────────────────────┘     (standby / new version)
```

The Service selector determines which pods receive traffic. Blue-green deployment is a single selector patch operation — it is atomic, instantaneous, and reversible without re-deploying anything.

**Key implementation requirements:**

1. Both versions must be deployed simultaneously before the switch
2. The new version must pass health checks and smoke tests before the switch
3. The switch should be automated and gated on test outcomes, not manual
4. The old version remains running after the switch to enable instant rollback
5. Old version pods are terminated only after the new version is confirmed stable

---

## Database Migration Coordination

The most complex aspect of blue-green deployment is database schema changes. If version 1.1 requires a column that does not exist in the database, the blue-green switch will cause errors in both versions simultaneously.

The **expand/contract** (or Parallel Change) pattern solves this:

1. **Expand**: Deploy a migration that adds new columns/tables but does not remove old ones. Both old and new application versions can run against this schema simultaneously.
2. **Migrate**: Deploy the new application version (green). Both versions work with the expanded schema.
3. **Contract**: After the new version is confirmed stable and the old version will not be rolled back to, remove the old columns/tables.

This pattern decouples database changes from application deployments — a prerequisite for safe blue-green operations in stateful applications.

---

## Change Management Evidence from Blue-Green

Blue-green deployments with GitOps produce a complete, auditable record of every release:

| Audit Evidence | Source |
|----------------|--------|
| Exact artifact deployed (digest) | Deployment manifest commit |
| Who approved the deployment | PR approval + merge author in Git |
| When traffic was switched | Git commit timestamp + deployment controller event |
| What health checks passed | Pipeline test results artifact |
| Rollback capability verified | Pre-deployment rollback test in staging |

For PCI-DSS Req 6.5.6 (separation of duties in change management) and SOX IT general controls, the Git merge approval workflow combined with automated deployment provides the required evidence without manual documentation.

---

## Lab Exercise

The lab for this chapter walks through:
1. Deploying blue and green versions of a sample application to Kubernetes
2. Configuring a Kubernetes Service to switch traffic between versions
3. Automating the smoke test gate before traffic switch
4. Performing a rollback by switching the selector back
5. Reviewing the deployment audit trail in Git history

See [lab/README.md](lab/README.md) to begin.

---

## Further Reading

- [release-orchestration-framework: progressive-delivery.md](../../../../release-orchestration-framework/docs/progressive-delivery.md) — canary, blue-green, and feature flags in production
- [release-orchestration-framework: database-migration-safety.md](../../../../release-orchestration-framework/docs/database-migration-safety.md) — expand/contract pattern in depth
- [release-orchestration-framework: gitops-architecture.md](../../../../release-orchestration-framework/docs/gitops-architecture.md) — GitOps delivery model for automated deployments
- [techstream-docs: dora-metrics-guide.md](../../../../techstream-docs/docs/dora-metrics-guide.md) — how deployment strategy affects Change Failure Rate and MTTR
