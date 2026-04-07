# Lab 5 — Generating DORA Metrics from Pipeline Data

**Estimated time:** 50–65 minutes
**Difficulty:** Intermediate
**Prerequisites:**
- Docker installed (for Grafana) OR ability to view JSON dashboard definitions
- Python 3.9+ installed
- Completed Book 1, Lab 4 (DORA baseline) is helpful but not required

---

## Overview

You will process a sample dataset of CI/CD pipeline events and incident records to compute DORA metrics, identify a metric regression, and load a pre-built Grafana dashboard to visualize the data.

The scenario: you are the engineering lead for Acme Financial Services. The CTO has requested a DORA metrics report for the Q1 board presentation and a risk assessment of the current delivery performance.

---

## Part 1: Compute All Four DORA Metrics (20 minutes)

Save this as `dora_metrics.py` and run it against the sample data in `examples/`:

```python
import csv
from datetime import datetime, timedelta
from collections import Counter
from statistics import median

# --- Load data ---
def load_csv(path):
    with open(path) as f:
        return list(csv.DictReader(f))

deployments = [
    r for r in load_csv("examples/pipeline-events.csv")
    if r["event_type"] == "deployment" and r["environment"] == "production" and r["status"] == "success"
]
incidents   = load_csv("examples/incident-events.csv")
commits     = load_csv("examples/commit-events.csv")

# --- Deployment Frequency ---
deploy_dates = [datetime.fromisoformat(d["timestamp"]).date() for d in deployments]
date_range   = (max(deploy_dates) - min(deploy_dates)).days + 1
deploy_freq  = len(deployments) / date_range

print(f"=== DORA Metrics Report ===\n")
print(f"Deployment Frequency: {deploy_freq:.2f}/day ({deploy_freq * 7:.1f}/week)")

# --- Lead Time ---
deploy_map = {d["event_id"]: datetime.fromisoformat(d["timestamp"]) for d in deployments}
lead_times = []
for c in commits:
    deploy_ts = deploy_map.get(c["deployment_id"])
    if deploy_ts:
        commit_ts = datetime.fromisoformat(c["committed_at"])
        lead_times.append((deploy_ts - commit_ts).total_seconds() / 3600)

print(f"Lead Time for Changes: {median(lead_times):.1f}h (median), {max(lead_times):.1f}h (max)")

# --- Change Failure Rate ---
failed_deploys = set(i["triggered_by_deployment"] for i in incidents if i["triggered_by_deployment"])
cfr = len(failed_deploys) / len(deployments) * 100
print(f"Change Failure Rate: {cfr:.1f}% ({len(failed_deploys)}/{len(deployments)} deployments)")

# --- MTTR ---
restore_times = []
for i in incidents:
    detected  = datetime.fromisoformat(i["detected_at"])
    resolved  = datetime.fromisoformat(i["resolved_at"])
    restore_times.append((resolved - detected).total_seconds() / 3600)
avg_mttr = sum(restore_times) / len(restore_times)
print(f"MTTR: {avg_mttr:.1f}h (average)\n")

# --- Tier classification ---
tiers = {
    "Deployment Frequency": "Elite" if deploy_freq >= 1 else ("High" if deploy_freq >= 1/7 else "Medium"),
    "Lead Time":            "Elite" if median(lead_times) < 1 else ("High" if median(lead_times) < 24 else "Medium"),
    "Change Failure Rate":  "Elite" if cfr <= 15 else ("High" if cfr <= 30 else "Low"),
    "MTTR":                 "Elite" if avg_mttr < 1 else ("High" if avg_mttr < 24 else "Medium"),
}
print("DORA Tier Classification:")
for metric, tier in tiers.items():
    print(f"  {metric}: {tier}")
overall = min(tiers.values(), key=lambda t: ["Elite", "High", "Medium", "Low"].index(t))
print(f"\nOverall tier: {overall}")
```

Run:
```bash
python dora_metrics.py
```

**Expected output:** Classification across all four metrics, plus overall tier.

---

## Part 2: Identify a Metric Regression (15 minutes)

The `examples/pipeline-events.csv` covers two months. Calculate metrics for Month 1 vs Month 2 separately to detect regression:

```python
import csv
from datetime import datetime
from statistics import median

events = []
with open("examples/pipeline-events.csv") as f:
    events = list(csv.DictReader(f))

for month in [1, 2]:
    month_deployments = [
        e for e in events
        if e["event_type"] == "deployment"
        and e["environment"] == "production"
        and e["status"] == "success"
        and datetime.fromisoformat(e["timestamp"]).month == month
    ]
    print(f"Month {month}: {len(month_deployments)} deployments")
```

If Month 2 shows fewer deployments and a higher CFR than Month 1, this is a regression signal. In a governance context, a two-month negative trend in CFR would trigger a change management review.

**Question:** Looking at the data, what is the probable cause of the regression? What change management action would you take?

---

## Part 3: Grafana Dashboard (20 minutes)

The `examples/grafana-dora-dashboard.json` is a Grafana dashboard definition that visualizes the four DORA metrics as time-series panels.

**To view in Grafana:**

```bash
# Start Grafana with Docker
docker run -d \
  --name grafana-lab \
  -p 3000:3000 \
  -e GF_AUTH_ANONYMOUS_ENABLED=true \
  -e GF_AUTH_ANONYMOUS_ORG_ROLE=Admin \
  grafana/grafana:10.4.0

# Access at http://localhost:3000
# Username: admin / Password: admin
```

Import the dashboard:
1. Navigate to Dashboards → Import
2. Upload `examples/grafana-dora-dashboard.json`
3. Review the four panels: Deployment Frequency, Lead Time (percentiles), CFR trend, MTTR trend

**Note:** The dashboard uses a TestData data source (built into Grafana) to simulate metric data. In production, you would replace this with a Prometheus, Loki, or PostgreSQL data source backed by your CI/CD and incident management systems.

**Review questions:**
- Which panel shows the regression from Part 2?
- What alert threshold would you configure for CFR to trigger a Slack notification?

---

## Part 4: Governance Risk Mapping (10 minutes)

Complete the risk mapping table using your calculated metrics:

| DORA Metric | Current Value | Risk Rating | Governance Action |
|------------|---------------|-------------|------------------|
| Deployment Frequency | ___ /day | Low / Medium / High | |
| Lead Time (median) | ___ hours | Low / Medium / High | |
| Change Failure Rate | ___% | Low / Medium / High | |
| MTTR | ___ hours | Low / Medium / High | |

**Risk rating guide:**
- **Low** = Elite or High DORA tier
- **Medium** = Medium DORA tier OR declining trend
- **High** = Low DORA tier OR two consecutive months of regression

**Governance actions for High risk:**
- CFR High: Mandatory post-incident review for all CFR-contributing deployments; security gate effectiveness audit
- MTTR High: Incident response runbook review; on-call escalation path drill
- Lead Time High: Batch size reduction initiative; CI pipeline performance review
- Deployment Frequency High: Change management process review; approval gate bottleneck analysis

---

## Cleanup

```bash
docker stop grafana-lab && docker rm grafana-lab
```

---

## Reflection Questions

1. Your CISO wants to add "Mean Time to Detect a Security Incident" to the DORA dashboard. How does this metric differ from MTTR? What data source would you use to calculate it?

2. A VP argues that CFR is unfair to measure because some "failures" are caused by upstream service degradation, not by the deployment itself. How would you refine the CFR definition to account for this? What are the risks of being too permissive in excluding incidents?

3. Acme's Lead Time is 6 days (High tier). A developer suggests that automating the change approval process would bring it under 1 day. A compliance officer objects that automated approvals violate the segregation of duties requirement for PCI-DSS. How would you resolve this tension?
