# Chapter 5 — DORA Metrics as Governance Signals

**Volume:** Book 4 — Release Engineering & DevSecOps Governance
**Framework reference:** [techstream-docs: dora-metrics-guide.md](../../../../techstream-docs/docs/dora-metrics-guide.md) | [release-orchestration-framework: framework.md](../../../../release-orchestration-framework/docs/framework.md)

---

## What You Will Learn

DORA metrics are not only a measure of engineering team performance — in a DevSecOps governance context, they are signals that surface delivery risk, security posture gaps, and compliance readiness. Engineering leaders who understand the governance implications of DORA metrics can use them to drive proactive risk management conversations rather than reactively responding to incidents.

By the end of this chapter, you will understand:

1. **DORA metrics in the governance context** — how Deployment Frequency, Lead Time, CFR, and MTTR map to risk signals for compliance and audit teams
2. **Change Failure Rate as a security indicator** — how CFR reveals gaps in pre-production security testing
3. **MTTR and security incident response** — how general MTTR capabilities translate to security incident containment time
4. **DORA metric collection from pipeline data** — automated collection from CI/CD systems and incident management platforms
5. **Reporting patterns** — what to show engineering teams, engineering leadership, and board-level stakeholders

---

## DORA Metrics as Risk Signals

### Deployment Frequency → Batch Size Risk

Low deployment frequency is a leading indicator of high batch size. Large batches mean:
- More changes per deployment — harder to identify which change caused an incident
- More security changes bundled together — harder to isolate the security impact of any single change
- Longer windows between security patches reaching production

For compliance purposes, low deployment frequency correlates with a higher probability of critical vulnerabilities remaining in production for extended periods. PCI-DSS Requirement 6.3 mandates that security vulnerabilities be addressed based on risk ranking — organizations with weekly or monthly deployments struggle to meet this requirement for critical findings.

### Lead Time → Vulnerability Exposure Window

Lead time directly determines the organization's maximum possible responsiveness to a zero-day vulnerability. If lead time is 3 weeks, a critical vulnerability disclosed on Monday cannot be patched in production until at most 3 weeks later — assuming the fix is the highest-priority work in every sprint.

Elite performers (lead time < 1 hour) can push emergency security patches to production within hours of a disclosure. This capability is increasingly relevant as exploit development timelines have shortened from months to days.

### Change Failure Rate → Pre-Production Testing Effectiveness

CFR measures what percentage of deployments cause incidents. A high CFR indicates that the pre-production testing pipeline is not catching defects before they reach users. In a security context, a high CFR also suggests that:
- Security testing gates may be insufficient or misconfigured
- Promotion gates are not enforcing vulnerability thresholds consistently
- The confidence in deployed artifacts is low

**Governance action:** CFR regression (trending up over 4–8 weeks) is an early warning signal for a change management review. Regulated organizations should treat sustained CFR > 20% as a risk finding requiring investigation.

### MTTR → Incident Response Capability

MTTR for production incidents is a leading indicator of security incident response capability. The skills and processes that enable fast MTTR — runbooks, clear on-call escalation, practiced rollback, good observability — are the same ones needed for security incident response.

Organizations with Elite MTTR (< 1 hour) typically also have:
- Pre-tested rollback procedures (critical for stopping active exploits)
- Observability that can detect anomalous behavior quickly
- Clear communication channels that work under incident pressure

---

## Collecting DORA Metrics from Pipeline Data

### Deployment Frequency

Extract from CI/CD pipeline execution logs, filtered to:
- Environment: production (or equivalent)
- Status: successful

Most CI/CD platforms expose this via API:
- GitHub Actions: `GET /repos/{owner}/{repo}/actions/runs?environment=production`
- GitLab: Pipeline API filtered by `status=success&ref=main&environment=production`
- Jenkins: Build history API filtered by environment tag

### Lead Time

Lead time requires correlating commit timestamps with deployment events:

1. For each production deployment, identify the set of commits included (git log range)
2. The lead time for that deployment = deployment timestamp − earliest commit timestamp in the set
3. Aggregate across deployments (use median, not mean)

### Change Failure Rate

CFR requires defining "failure" consistently:
- Rollbacks triggered by the deployment
- Hotfixes deployed within 24 hours of the original deployment
- Incidents with `triggered_by_deployment` populated in the incident management system

The definition must be agreed on by engineering and operations before measurement begins — inconsistent definitions produce misleading data.

### MTTR

MTTR = (sum of incident resolution times) / (count of incidents)

Where resolution time = `resolved_at − detected_at` in the incident management system.

**Note:** "Detected" should mean the time the incident was declared, not the time monitoring first fired. Monitoring alerts that go unacknowledged for 20 minutes before incident declaration will inflate MTTR if the alert time is used.

---

## Reporting Patterns by Audience

| Audience | What they care about | Metrics to emphasize | Format |
|----------|---------------------|---------------------|--------|
| Engineering teams | Are we getting faster? Where are we stuck? | All four metrics, trend over time | Weekly dashboard |
| Engineering leadership | Is delivery reliable? Are we managing risk? | CFR trend, MTTR trend, tier classification | Monthly summary |
| CISO / Risk | How quickly can we respond to a vulnerability? | Lead time, MTTR, vulnerability escape rate | Quarterly risk review |
| Audit / Compliance | Can we demonstrate deployment controls? | CFR with root cause categories, change approval rate | Annual audit evidence |

---

## Lab Exercise

The lab for this chapter walks through:

1. Extracting DORA metrics from a sample dataset of pipeline events and incidents
2. Building a Grafana dashboard JSON template for DORA metric visualization
3. Identifying metric regressions that would trigger a governance review
4. Mapping DORA metric values to risk ratings for a compliance report

See [lab/README.md](lab/README.md) to begin.

---

## Further Reading

- [techstream-docs: dora-metrics-guide.md](../../../../techstream-docs/docs/dora-metrics-guide.md) — DORA implementation guide with collection patterns
- [devsecops-maturity-model: metrics-kpis.md](../../../../devsecops-maturity-model/docs/metrics-kpis.md) — security KPIs that complement DORA metrics
- [Chapter 4 (Book 1) — Establishing a DORA Baseline](../../book-1-foundations/ch04-dora-metrics-baseline/README.md) — how to collect your first baseline
- [release-orchestration-framework: framework.md](../../../../release-orchestration-framework/docs/framework.md) — release governance framework context
