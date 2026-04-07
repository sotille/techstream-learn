# Chapter 4 — Establishing a DORA Metrics Baseline

**Volume:** Book 1 — DevSecOps: Foundations & Transformation
**Framework reference:** [techstream-docs: dora-metrics-guide.md](../../../../techstream-docs/docs/dora-metrics-guide.md) | [devsecops-maturity-model: metrics-kpis.md](../../../../devsecops-maturity-model/docs/metrics-kpis.md)

---

## What You Will Learn

You cannot improve what you cannot measure. Before investing in DevSecOps tooling, process changes, or organizational restructuring, you need a measurement baseline that tells you where you are starting from. DORA metrics — Deployment Frequency, Lead Time for Changes, Change Failure Rate, and Mean Time to Restore — provide a concise, research-backed picture of software delivery performance that correlates directly with both organizational performance and security outcomes.

By the end of this chapter, you will understand:

1. **What the four DORA metrics measure** — and why this specific set was chosen
2. **How to collect each metric** — from Git events, pipeline data, and incident management systems
3. **DORA performance tiers** — what "Elite," "High," "Medium," and "Low" performers look like in practice
4. **Security KPIs to pair with DORA** — the security-specific measurements that complement delivery performance metrics
5. **How to present this data** — dashboards, trends, and what to report to different audiences

---

## The Four DORA Metrics

The DORA metrics were developed from the State of DevOps research program (now part of Google) through surveys of thousands of technology teams. The research identified these four metrics as the most predictive of organizational performance — teams that score Elite on these metrics are also more profitable, grow faster, and have lower employee burnout.

### Deployment Frequency

**What it measures:** How often code is deployed to production.

**Collection source:** Pipeline run logs or deployment events filtered by environment = production.

**DORA tiers:**
| Tier | Deployment frequency |
|------|---------------------|
| Elite | Multiple times per day |
| High | Once per day to once per week |
| Medium | Once per week to once per month |
| Low | Less than once per month |

**DevSecOps implication:** Low deployment frequency correlates with large batch sizes — which means higher risk per deployment and longer windows between security fixes reaching production. Elite performers deploy small, safe changes continuously.

### Lead Time for Changes

**What it measures:** The time from "code committed" to "code running in production."

**Collection source:** Timestamp of the first commit in a change set → timestamp of the production deployment that includes that commit.

**DORA tiers:**
| Tier | Lead time |
|------|-----------|
| Elite | Less than one hour |
| High | One day to one week |
| Medium | One week to one month |
| Low | One month to six months |

**DevSecOps implication:** Long lead times create security debt. A vulnerability discovered in code review that takes 3 weeks to reach production is 3 weeks of exposure. Lead time is also the upper bound on how quickly a security patch can reach users.

### Change Failure Rate

**What it measures:** The percentage of deployments that cause a production incident requiring rollback, hotfix, or emergency change.

**Collection source:** Number of incident-causing deployments / total deployments. Incident data typically comes from an incident management system (PagerDuty, OpsGenie, incident Slack channels).

**DORA tiers:**
| Tier | Change failure rate |
|------|-------------------|
| Elite | 0–15% |
| High | 16–30% |
| Medium | 16–30% (same range, different reliability indicators) |
| Low | > 30% |

**DevSecOps implication:** High change failure rate indicates insufficient pre-production testing — including security testing. Security gates (SAST, SCA, secrets detection) that prevent vulnerable code from reaching production directly reduce change failure rate.

### Mean Time to Restore (MTTR)

**What it measures:** How long it takes to recover from a production incident (from detection to resolution).

**Collection source:** Incident creation timestamp → incident resolution timestamp in the incident management system.

**DORA tiers:**
| Tier | MTTR |
|------|------|
| Elite | Less than one hour |
| High | Less than one day |
| Medium | One day to one week |
| Low | More than one week |

**DevSecOps implication:** MTTR for security incidents measures how quickly a breach or vulnerability can be contained. Teams with fast MTTR have practiced rollback, have well-instrumented systems, and have clear incident response procedures.

---

## Security KPIs to Pair with DORA

DORA metrics measure delivery reliability. They do not directly measure security posture. Pair them with these security-specific KPIs:

| Security KPI | Description | Collection source |
|-------------|-------------|------------------|
| Mean Time to Detect (MTTD) | Time from vulnerability introduction to detection | SAST/SCA scan timestamp vs. commit timestamp |
| Vulnerability Escape Rate | % of Critical/High vulnerabilities that reach production undetected | Vulnerabilities found in prod / total vulnerabilities found |
| Secrets Exposure Incidents | Count of credentials exposed in repositories or logs per quarter | Git scanning alerts + incident log |
| Dependency Hygiene Score | % of dependencies within N days of latest version | SCA tool reports |
| SBOM Coverage | % of production artifacts with attached, valid SBOM | Artifact registry attestation check |

---

## Lab Exercise

The lab for this chapter guides you through establishing a DORA metrics baseline for a sample organization using pipeline data:

1. Calculating Deployment Frequency from a sample deployment log
2. Calculating Lead Time from commit timestamps and deployment events
3. Categorizing the organization into a DORA performance tier
4. Identifying the security KPIs most relevant to your team's risk profile
5. Building a one-page metrics dashboard template

See [lab/README.md](lab/README.md) to begin.

---

## Further Reading

- [techstream-docs: dora-metrics-guide.md](../../../../techstream-docs/docs/dora-metrics-guide.md) — full DORA implementation guide with data collection patterns
- [devsecops-maturity-model: metrics-kpis.md](../../../../devsecops-maturity-model/docs/metrics-kpis.md) — security KPIs and how they map to TDMM domains
- [devsecops-maturity-model: metrics-gaming-prevention.md](../../../../devsecops-maturity-model/docs/metrics-gaming-prevention.md) — preventing teams from optimizing for the metric rather than the outcome
