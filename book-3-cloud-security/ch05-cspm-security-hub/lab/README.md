# Lab 5 — CSPM Alerting with AWS Security Hub

**Estimated time:** 50–65 minutes
**Difficulty:** Intermediate
**Prerequisites:**
- An AWS account with administrator access (a personal test account is sufficient)
- AWS CLI installed and configured (`aws configure`)
- Python 3.9+ installed
- A Slack workspace where you can create an incoming webhook (optional — for Part 3)

**Cost notice:** AWS Security Hub costs ~$0.001 per finding ingested. Enabling it for this lab will incur minimal charges (typically < $1 for a short session). Remember to disable Security Hub at the end of the lab to avoid ongoing costs.

---

## Part 1: Enable Security Hub and Review CIS Findings (15 minutes)

### Step 1 — Enable Security Hub

```bash
# Enable Security Hub in your test region
aws securityhub enable-security-hub \
  --enable-default-standards \
  --region us-east-1

# Verify it is enabled
aws securityhub describe-hub --region us-east-1
```

### Step 2 — Wait for initial evaluation

Security Hub runs its initial compliance evaluation within 2–5 minutes of enabling. The CIS AWS Foundations Benchmark runs automatically.

```bash
# Check the status of CIS benchmark evaluation
aws securityhub get-enabled-standards --region us-east-1

# List the first 10 failing controls
aws securityhub get-compliance-summary-by-config-rule \
  --region us-east-1 2>/dev/null || \
aws securityhub list-standards-control-associations \
  --standards-arn "arn:aws:securityhub:us-east-1::standards/cis-aws-foundations-benchmark/v/1.4.0" \
  --region us-east-1 | python3 -m json.tool | head -80
```

### Step 3 — Review findings

```bash
# Get Critical and High severity findings
aws securityhub get-findings \
  --filters '{"SeverityLabel":[{"Value":"CRITICAL","Comparison":"EQUALS"},{"Value":"HIGH","Comparison":"EQUALS"}]}' \
  --region us-east-1 \
  --query 'Findings[*].{Title: Title, Severity: Severity.Label, Control: ProductFields.ControlId}' \
  --output table
```

**Discussion:** How many Critical findings does a new AWS account have? What categories do they fall into? Are any findings surprising?

---

## Part 2: Create an EventBridge Alerting Rule (15 minutes)

This section sets up routing for Critical Security Hub findings to a CloudWatch log group (and optionally to Slack).

### Step 1 — Create EventBridge rule

```bash
# Create a rule that captures Critical Security Hub findings
aws events put-rule \
  --name "SecurityHub-Critical-Findings" \
  --event-pattern '{
    "source": ["aws.securityhub"],
    "detail-type": ["Security Hub Findings - Imported"],
    "detail": {
      "findings": {
        "Severity": {
          "Label": ["CRITICAL"]
        },
        "Workflow": {
          "Status": ["NEW"]
        }
      }
    }
  }' \
  --state ENABLED \
  --region us-east-1
```

### Step 2 — Create CloudWatch Logs target

```bash
# Create log group for Security Hub findings
aws logs create-log-group \
  --log-group-name /securityhub/critical-findings \
  --region us-east-1

# Get the log group ARN
LOG_GROUP_ARN=$(aws logs describe-log-groups \
  --log-group-name-prefix /securityhub/critical-findings \
  --region us-east-1 \
  --query 'logGroups[0].arn' \
  --output text)

# Add CloudWatch Logs as the target
aws events put-targets \
  --rule SecurityHub-Critical-Findings \
  --targets "Id=1,Arn=${LOG_GROUP_ARN}" \
  --region us-east-1
```

### Step 3 — Review the Slack webhook Lambda (optional)

Review `examples/slack-notifier-lambda.py` — this Lambda function translates Security Hub findings to Slack messages. It is not deployed in this lab (to avoid costs), but review the code to understand:
1. How ASFF finding fields map to Slack message fields
2. How the Lambda filters for alert-worthy vs. informational findings

---

## Part 3: Write a Custom Config Rule (15 minutes)

This section implements a custom organization policy: "all S3 buckets must have a CostCenter tag."

Review `examples/custom-config-rule.py` — the Lambda function for the custom Config Rule.

### Deploy the Config Rule (requires Lambda permissions):

```bash
# Package the Lambda function
zip custom-rule.zip examples/custom-config-rule.py

# Create the Lambda function
aws lambda create-function \
  --function-name SecurityHub-S3TagCompliance \
  --runtime python3.12 \
  --handler custom-config-rule.lambda_handler \
  --zip-file fileb://custom-rule.zip \
  --role arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/lambda-config-role \
  --region us-east-1 2>/dev/null || echo "Lambda role may not exist — review examples/iam-role-policy.json"
```

**Note:** Full deployment requires an IAM role with Config and SecurityHub permissions. Review `examples/iam-role-policy.json` for the required policy if your account does not have a suitable role.

---

## Part 4: Generate a Compliance Summary Report (10 minutes)

```python
# compliance-report.py — Generate a Security Hub compliance summary
import boto3
import json
from datetime import datetime

client = boto3.client('securityhub', region_name='us-east-1')

# Get findings grouped by severity
findings_summary = {"CRITICAL": 0, "HIGH": 0, "MEDIUM": 0, "LOW": 0}

paginator = client.get_paginator('get_findings')
for page in paginator.paginate(
    Filters={"WorkflowStatus": [{"Value": "NEW", "Comparison": "EQUALS"}]}
):
    for finding in page['Findings']:
        severity = finding.get('Severity', {}).get('Label', 'UNKNOWN')
        if severity in findings_summary:
            findings_summary[severity] += 1

print(f"AWS Security Hub — Compliance Summary")
print(f"Generated: {datetime.now().isoformat()}")
print(f"Region: us-east-1\n")
print(f"Open findings by severity:")
for severity, count in findings_summary.items():
    print(f"  {severity}: {count}")

total = sum(findings_summary.values())
print(f"\nTotal open findings: {total}")
print(f"\nNote: For SOC 2 evidence, export this report monthly and store in the compliance artifact store.")
```

Run:
```bash
python3 compliance-report.py
```

---

## Cleanup

```bash
# Disable Security Hub (stops ongoing charges)
aws securityhub disable-security-hub --region us-east-1

# Remove EventBridge rule
aws events remove-targets --rule SecurityHub-Critical-Findings --ids 1 --region us-east-1
aws events delete-rule --name SecurityHub-Critical-Findings --region us-east-1

# Remove CloudWatch log group
aws logs delete-log-group --log-group-name /securityhub/critical-findings --region us-east-1
```

---

## Reflection Questions

1. Security Hub found 3 Critical findings in your new test account — all related to the root account (no MFA, access keys exist). These are real findings that would exist in any new account. What does this tell you about the baseline security posture of a "fresh" AWS account, and what should be the first action in any new account provisioning runbook?

2. A developer argues that the CIS benchmark is too strict — "half these findings don't apply to our threat model." How would you evaluate whether a specific CIS control is relevant to your organization? What is the risk of suppressing controls without a documented rationale?

3. Auto-remediation removed an overpermissive security group rule, but this caused an outage because the rule was intentionally permissive for a third-party integration. What governance controls would you add to the auto-remediation workflow to prevent this?
