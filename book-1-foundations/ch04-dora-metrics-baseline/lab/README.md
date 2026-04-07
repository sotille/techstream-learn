# Lab 4 — Establishing a DORA Metrics Baseline

**Estimated time:** 45–60 minutes
**Difficulty:** Beginner
**Format:** Data analysis exercise using sample CSV data and Python (or spreadsheet)
**Prerequisites:** Basic spreadsheet or Python familiarity

---

## Overview

You will analyze a sample dataset of pipeline deployments and incidents to calculate DORA metrics for a fictional organization (Acme Financial Services), classify them into a DORA performance tier, and produce a metrics summary suitable for an engineering leadership review.

The dataset represents 90 days of deployment and incident data.

---

## Setup

The sample data files are in `examples/`:
- `deployment-log.csv` — one row per production deployment
- `incident-log.csv` — one row per production incident with deployment reference
- `commit-log.csv` — sample of commit timestamps and associated deployment IDs

---

## Part 1: Calculate Deployment Frequency (10 minutes)

Open `examples/deployment-log.csv`. Each row is a production deployment with columns: `deployment_id`, `timestamp`, `service`, `environment`, `deployed_by`.

**Using Python:**

```python
import csv
from datetime import datetime
from collections import Counter

deployments = []
with open("examples/deployment-log.csv") as f:
    reader = csv.DictReader(f)
    for row in reader:
        if row["environment"] == "production":
            deployments.append(datetime.fromisoformat(row["timestamp"]))

# Count deployments per day
by_date = Counter(d.date() for d in deployments)
total_days = (max(by_date) - min(by_date)).days + 1
avg_per_day = len(deployments) / total_days

print(f"Total production deployments: {len(deployments)}")
print(f"Period: {min(by_date)} to {max(by_date)} ({total_days} days)")
print(f"Average deployments per day: {avg_per_day:.2f}")
print(f"Average deployments per week: {avg_per_day * 7:.1f}")
```

**Question:** Based on the DORA tier table, what tier is this organization for Deployment Frequency?

---

## Part 2: Calculate Lead Time for Changes (15 minutes)

Lead time = time from first commit in the change → production deployment timestamp.

Open `examples/commit-log.csv` (columns: `commit_id`, `committed_at`, `deployment_id`) and `examples/deployment-log.csv`.

```python
import csv
from datetime import datetime

# Load deployments indexed by ID
deployments = {}
with open("examples/deployment-log.csv") as f:
    for row in csv.DictReader(f):
        if row["environment"] == "production":
            deployments[row["deployment_id"]] = datetime.fromisoformat(row["timestamp"])

# Calculate lead time for each commit
lead_times = []
with open("examples/commit-log.csv") as f:
    for row in csv.DictReader(f):
        deploy_ts = deployments.get(row["deployment_id"])
        if deploy_ts:
            commit_ts = datetime.fromisoformat(row["committed_at"])
            lead_time_hours = (deploy_ts - commit_ts).total_seconds() / 3600
            lead_times.append(lead_time_hours)

avg_lead_time = sum(lead_times) / len(lead_times)
median_lead_time = sorted(lead_times)[len(lead_times) // 2]
p90_lead_time = sorted(lead_times)[int(len(lead_times) * 0.90)]

print(f"Lead Time for Changes:")
print(f"  Average: {avg_lead_time:.1f} hours")
print(f"  Median:  {median_lead_time:.1f} hours")
print(f"  P90:     {p90_lead_time:.1f} hours")
```

**Note:** DORA recommends reporting the median (P50) lead time. The P90 reveals the long tail — the slowest 10% of changes. A large gap between median and P90 often indicates a category of changes (large features, hotfixes) with a different delivery pattern.

---

## Part 3: Calculate Change Failure Rate and MTTR (10 minutes)

Open `examples/incident-log.csv` (columns: `incident_id`, `triggered_by_deployment`, `detected_at`, `resolved_at`, `severity`).

```python
import csv
from datetime import datetime

incidents = []
with open("examples/incident-log.csv") as f:
    for row in csv.DictReader(f):
        incidents.append(row)

# Change Failure Rate
total_deployments = len(deployments)
failure_deployments = len(set(i["triggered_by_deployment"] for i in incidents if i["triggered_by_deployment"]))
cfr = failure_deployments / total_deployments * 100

# MTTR
restore_times = []
for i in incidents:
    detected = datetime.fromisoformat(i["detected_at"])
    resolved = datetime.fromisoformat(i["resolved_at"])
    restore_times.append((resolved - detected).total_seconds() / 3600)

avg_mttr = sum(restore_times) / len(restore_times)

print(f"Change Failure Rate: {cfr:.1f}% ({failure_deployments}/{total_deployments} deployments)")
print(f"MTTR (average): {avg_mttr:.1f} hours")
```

---

## Part 4: DORA Tier Classification and Dashboard (15 minutes)

Complete the tier classification table using your calculated values:

| Metric | Acme's Value | DORA Tier |
|--------|-------------|-----------|
| Deployment Frequency | ___ per day | [Elite / High / Medium / Low] |
| Lead Time for Changes | ___ hours (median) | [Elite / High / Medium / Low] |
| Change Failure Rate | ___% | [Elite / High / Medium / Low] |
| MTTR | ___ hours | [Elite / High / Medium / Low] |

**Overall tier:** Most organizations use the lowest tier across all four metrics as their overall classification.

**Improvement priority:** If Acme is Medium on CFR but High on everything else, where should the improvement investment go? Use the [devsecops-maturity-model: metrics-kpis.md](../../../../../devsecops-maturity-model/docs/metrics-kpis.md) to identify which TDMM domains address Change Failure Rate.

---

## Part 5: Security KPI Baseline (10 minutes)

Using `examples/vulnerability-log.csv` (columns: `vuln_id`, `discovered_at`, `environment`, `severity`, `resolved_at`):

Calculate:
1. **Vulnerability Escape Rate** = vulnerabilities first discovered in production / total vulnerabilities
2. **Mean Time to Detect (MTTD)** = average time from introduction (use `committed_at` from commit log) to discovery

```python
# (Implement using the pattern from Parts 1-3)
```

**Discussion:** How does your Vulnerability Escape Rate compare to your Change Failure Rate? A high escape rate with a low CFR suggests vulnerabilities are not being counted as "failures" — an alignment problem between security and operations metrics.

---

## Deliverable

Produce a one-page metrics summary with:
- The four DORA metrics with current values and DORA tier
- Two security KPIs (escape rate and MTTD) with current values
- The top one improvement recommendation (the metric with the biggest gap from the next DORA tier)
- One chart (bar or line) showing deployment frequency trend over the 90-day period

---

## Reflection Questions

1. Your organization's CFR is 28%. An engineering leader proposes reducing it by adding more pre-production environments. What are the risks of this approach from a DevSecOps perspective?

2. Your MTTD is 14 days — vulnerabilities introduced in code are not detected until two weeks later. What pipeline changes would reduce MTTD to under 24 hours?

3. The DORA program recommends using median lead time, not mean. Why? What types of outliers would skew the mean and make it misleading for capacity planning?
