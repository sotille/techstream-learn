# Lab 2 — Cloud Identity Threats: IAM Audit and Least-Privilege Enforcement

**Chapter:** 2 — Cloud Identity Threats
**Volume:** Book 3 — Cloud-Native Security for DevSecOps
**Estimated time:** 50–65 minutes
**Difficulty:** Intermediate
**Prerequisites:** AWS CLI configured (read-only access sufficient for Steps 1–3), Python 3.8+, Terraform, Checkov

---

## Objectives

By the end of this lab you will be able to:
- Run Cloudsplaining against an IAM configuration export to identify privilege escalation paths
- Interpret IAM Access Analyzer findings for external access exposure
- Enforce IMDSv2 via Terraform and verify the Checkov scan passes
- Read a CloudTrail log and identify credential theft indicators
- Write an ABAC-scoped IAM policy for a deployment pipeline

---

## Step 1 — Export and Analyze IAM Policies with Cloudsplaining

### 1a — Install Cloudsplaining

```bash
pip install cloudsplaining
```

### 1b — Export IAM Authorization Details

Cloudsplaining analyzes a JSON export of your account's IAM configuration. Run this against your AWS account (requires `iam:GenerateCredentialReport` and `iam:GetAccountAuthorizationDetails` permissions):

```bash
cloudsplaining download --profile default --output iam-export.json
```

If you do not have an AWS account configured, use the example export provided in `examples/iam-export-sample.json`.

### 1c — Run the Analysis

```bash
cloudsplaining scan --input-file iam-export.json --output cloudsplaining-report/
```

This generates an HTML report and a JSON findings file.

### 1d — Interpret the Report

Open `cloudsplaining-report/index.html` in a browser. For each IAM principal listed:

1. Note which principals have **Privilege Escalation** findings — these can obtain higher permissions than intended
2. Note which principals have **Data Exfiltration** findings — these can read sensitive data stores directly
3. Note which principals have **Resource Exposure** findings — these can make resources publicly accessible

**Exercise:** Identify the three highest-risk IAM entities in the report. For each, write:
- The entity name (user, role, or group)
- The specific finding category (escalation, exfiltration, or exposure)
- The specific IAM permission creating the risk
- A proposed least-privilege alternative

---

## Step 2 — Examine the Sample Overpermissioned Policy

Review the example policy in `examples/overpermissioned-policy.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DeploymentRole",
      "Effect": "Allow",
      "Action": [
        "iam:PassRole",
        "iam:CreatePolicy",
        "iam:CreatePolicyVersion",
        "ec2:RunInstances",
        "s3:*",
        "lambda:*"
      ],
      "Resource": "*"
    }
  ]
}
```

**Analysis questions:**

1. Which specific permissions in this policy create a privilege escalation path to administrator access?
2. What is the minimum permission set actually needed for a deployment pipeline that deploys Lambda functions and reads from an S3 artifact bucket?
3. Rewrite the policy with least-privilege permissions for that specific use case. Add resource-level restrictions where possible (e.g., restrict `s3:GetObject` to a specific bucket ARN).

**Reference answer for Question 1:**
- `iam:CreatePolicyVersion` allows creating a new policy version with `"Action": "*"` — direct privilege escalation
- `iam:PassRole` + `ec2:RunInstances` allows launching an instance with a high-privilege role
- `lambda:*` + `iam:PassRole` allows creating a Lambda with a high-privilege execution role

---

## Step 3 — Enforce IMDSv2 with Terraform and Checkov

### 3a — Review the Vulnerable Configuration

Examine `examples/terraform/ec2-vulnerable.tf`. This EC2 instance configuration allows IMDSv1 (no session token required):

```hcl
resource "aws_instance" "app_server" {
  ami           = "ami-0c02fb55956c7d316"
  instance_type = "t3.micro"

  # metadata_options block absent — defaults to IMDSv1 allowed
  tags = {
    Name = "app-server"
  }
}
```

Run Checkov against it and observe the failure:

```bash
checkov -f examples/terraform/ec2-vulnerable.tf --check CKV_AWS_79
```

Expected output: `FAILED for resource: aws_instance.app_server`

### 3b — Fix the Configuration

Examine `examples/terraform/ec2-hardened.tf`. This version enforces IMDSv2:

```hcl
resource "aws_instance" "app_server" {
  ami           = "ami-0c02fb55956c7d316"
  instance_type = "t3.micro"

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"   # IMDSv2 enforced
    http_put_response_hop_limit = 1            # Prevents container-to-host metadata access
  }

  tags = {
    Name = "app-server"
  }
}
```

Run Checkov against the hardened version:

```bash
checkov -f examples/terraform/ec2-hardened.tf --check CKV_AWS_79
```

Expected output: `PASSED for resource: aws_instance.app_server`

### 3c — Verify Additional Controls

Run a broader Checkov scan on both files to compare the full finding delta:

```bash
checkov -f examples/terraform/ec2-vulnerable.tf --output json | jq '.results.failed_checks | length'
checkov -f examples/terraform/ec2-hardened.tf --output json | jq '.results.failed_checks | length'
```

Record the number of failing checks before and after. The hardened configuration should have zero failures for the instance metadata, encryption, and IAM controls checked.

---

## Step 4 — Trace a Credential Theft in CloudTrail

Review the sample CloudTrail log in `examples/cloudtrail-credential-theft.json`. This log represents a simulated credential theft scenario using SSRF to query the instance metadata service.

```json
[
  {
    "eventTime": "2026-04-07T14:23:11Z",
    "eventSource": "ec2.amazonaws.com",
    "eventName": "DescribeInstances",
    "sourceIPAddress": "203.0.113.42",
    "userAgent": "python-requests/2.28.0",
    "userIdentity": {
      "type": "AssumedRole",
      "arn": "arn:aws:sts::123456789012:assumed-role/web-app-role/i-0abc123def456"
    }
  },
  {
    "eventTime": "2026-04-07T14:23:15Z",
    "eventSource": "s3.amazonaws.com",
    "eventName": "ListBuckets",
    "sourceIPAddress": "203.0.113.42",
    "userIdentity": {
      "type": "AssumedRole",
      "arn": "arn:aws:sts::123456789012:assumed-role/web-app-role/i-0abc123def456"
    }
  },
  {
    "eventTime": "2026-04-07T14:24:02Z",
    "eventSource": "s3.amazonaws.com",
    "eventName": "GetObject",
    "sourceIPAddress": "203.0.113.42",
    "requestParameters": {
      "bucketName": "company-financials-backup",
      "key": "2025/Q4/revenue-report.xlsx"
    },
    "userIdentity": {
      "type": "AssumedRole",
      "arn": "arn:aws:sts::123456789012:assumed-role/web-app-role/i-0abc123def456"
    }
  }
]
```

**Analysis questions:**

1. What anomalous behavior is visible in this log sequence that should trigger an alert?
2. `web-app-role` is the role attached to an EC2 instance running a web application. Why is `DescribeInstances` from an external IP address suspicious for this role?
3. What CloudWatch metric filter or Athena query would you write to detect `ListBuckets` from roles that are not expected to enumerate buckets?
4. What IAM permission boundary or SCP would have prevented the `GetObject` call on `company-financials-backup`?

**Reference detection query (Athena, CloudTrail Lake):**

```sql
SELECT
    eventTime,
    eventName,
    sourceIPAddress,
    userIdentity.arn,
    requestParameters
FROM cloudtrail_logs
WHERE eventName IN ('ListBuckets', 'DescribeInstances')
  AND userIdentity.arn LIKE '%web-app-role%'
  AND sourceIPAddress NOT LIKE '10.%'
  AND sourceIPAddress NOT LIKE '172.%'
ORDER BY eventTime DESC
LIMIT 100;
```

---

## Step 5 — Write an ABAC-Scoped Deployment Pipeline Policy

Your organization has the following tagging convention:
- Pipelines are tagged: `team=payments`, `env=prod`
- S3 buckets are tagged: `team=payments`, `data-classification=internal`
- Lambda functions are tagged: `team=payments`, `env=prod`

Write an ABAC IAM policy for the payments deployment pipeline role that:
1. Allows `s3:GetObject` and `s3:PutObject` only on S3 objects tagged `team=payments`
2. Allows `lambda:UpdateFunctionCode` only on Lambda functions tagged `team=payments` and `env=prod`
3. Allows `lambda:InvokeFunction` for smoke tests — same tag scope
4. Explicitly denies any action on resources tagged `data-classification=confidential`

Use the `aws:ResourceTag` condition key for resource-based restrictions and `aws:PrincipalTag` to bind to the caller's own tags.

**Reference structure:**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "S3DeployArtifacts",
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:PutObject"],
      "Resource": "arn:aws:s3:::*/*",
      "Condition": {
        "StringEquals": {
          "aws:ResourceTag/team": "${aws:PrincipalTag/team}"
        }
      }
    },
    {
      "Sid": "DenyConfidentialData",
      "Effect": "Deny",
      "Action": "*",
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "aws:ResourceTag/data-classification": "confidential"
        }
      }
    }
  ]
}
```

Complete the remaining statements for Lambda `UpdateFunctionCode` and `InvokeFunction`.

---

## Deliverables

After completing this lab, you should have:

1. A Cloudsplaining findings summary listing the three highest-risk IAM principals and your proposed remediations
2. A rewritten least-privilege IAM policy for the deployment role from Step 2
3. The Checkov scan pass/fail count before and after the IMDSv2 fix
4. Answers to the four CloudTrail analysis questions in Step 4
5. A complete ABAC IAM policy for the payments pipeline from Step 5

---

## Extension Exercise

If you have a real AWS account with CloudTrail enabled:

1. Run `aws cloudtrail lookup-events --lookup-attributes AttributeKey=EventName,AttributeValue=AssumeRole --max-items 50` and identify any unexpected `AssumeRole` chains
2. Use AWS IAM Access Analyzer to scan your account for IAM roles accessible from external principals
3. Run Cloudsplaining against your own account's IAM export and compare findings to this lab's sample

---

## References

- [Chapter 2 overview](../README.md)
- [cloud-security-devsecops: zero-trust-architecture.md](../../../../../cloud-security-devsecops/docs/zero-trust-architecture.md)
- Cloudsplaining documentation: `cloudsplaining.readthedocs.io`
- AWS IAM Access Analyzer: `docs.aws.amazon.com/IAM/latest/UserGuide/what-is-access-analyzer.html`
- AWS ABAC documentation: `docs.aws.amazon.com/IAM/latest/UserGuide/introduction_attribute-based-access-control.html`
