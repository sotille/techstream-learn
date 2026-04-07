# Chapter 5 — CSPM Alerting with AWS Security Hub

**Volume:** Book 3 — Cloud-Native Security for DevSecOps
**Framework reference:** [cloud-security-devsecops: cnapp-integration.md](../../../../cloud-security-devsecops/docs/cnapp-integration.md) | [cloud-security-devsecops: architecture.md](../../../../cloud-security-devsecops/docs/architecture.md)

---

## What You Will Learn

Cloud Security Posture Management (CSPM) tools continuously evaluate deployed cloud infrastructure against security benchmarks and alert on drift from the desired configuration. Unlike IaC scanning (which catches misconfigurations before deployment), CSPM operates on the live cloud environment — it detects what is actually running, not what the code says should be running. This distinction matters because infrastructure changes happen outside the deployment pipeline: manual console changes, auto-scaling events, and third-party integrations can all introduce configuration drift that IaC scanning would never see.

By the end of this chapter, you will understand:

1. **CSPM vs. IaC scanning** — the difference in coverage, timing, and remediation workflow
2. **AWS Security Hub architecture** — how Security Hub aggregates findings from native AWS services (GuardDuty, Inspector, Macie) and third-party integrations
3. **CIS AWS Foundations Benchmark** — the standard baseline Security Hub enforces out of the box
4. **Custom Security Hub controls** — how to write organization-specific controls for policies not covered by the standard benchmark
5. **Alerting and remediation workflows** — routing Security Hub findings to Slack, PagerDuty, and automated remediation Lambda functions

---

## CSPM vs. IaC Scanning

IaC scanning and CSPM address the same category of problem — cloud misconfiguration — but at different points in the lifecycle:

| Dimension | IaC Scanning (Checkov, Trivy) | CSPM (AWS Security Hub, Defender for Cloud) |
|-----------|-------------------------------|---------------------------------------------|
| When it runs | At code review / CI pipeline time | Continuously against live infrastructure |
| What it scans | Terraform / CloudFormation templates | Actual deployed AWS resources |
| Coverage | Only resources defined in IaC | All resources, including manually created ones |
| Latency to detect | Immediate (blocks pipeline) | Minutes to hours after misconfiguration occurs |
| False positive rate | Higher (template-level, no runtime context) | Lower (evaluates real resource state) |
| Remediation | Code change → PR → pipeline | Direct resource modification or IaC correction |

**The key insight:** IaC scanning and CSPM are not alternatives — they are complementary layers. IaC scanning prevents known-bad configurations from being deployed. CSPM detects drift after deployment and catches what IaC scanning misses.

---

## AWS Security Hub Architecture

Security Hub operates as a centralized aggregator of security findings across your AWS account and organization:

```
AWS GuardDuty ──────────────────┐
AWS Inspector ──────────────────┤
AWS Macie ──────────────────────┤──► AWS Security Hub ──► EventBridge ──► Slack / PagerDuty
Third-party (Crowdstrike, etc.) ┤          │                               Lambda (auto-remediation)
Custom findings (your Lambda) ──┘          │
                                           ▼
                                  Security Hub Controls
                                  (CIS Benchmark, NIST, PCI-DSS)
```

Security Hub uses the AWS Security Finding Format (ASFF) — a normalized JSON schema that all findings, regardless of source, conform to. This normalization enables consistent alerting rules regardless of which service detected the finding.

---

## CIS AWS Foundations Benchmark

The CIS AWS Foundations Benchmark is a prescriptive set of security controls for AWS accounts. Security Hub enables CIS benchmark evaluation out of the box. Key control categories:

**Identity and Access Management:**
- Avoid root account usage (MFA required on root)
- No access keys for root account
- IAM password policy enforces complexity requirements
- MFA enabled for all IAM users with console access

**Logging:**
- CloudTrail enabled in all regions
- CloudTrail log file validation enabled
- CloudWatch log metric filters and alarms for console sign-in without MFA

**Networking:**
- No security groups allow unrestricted inbound access on port 22 (SSH) or 3389 (RDP)
- Default VPC security group restricts all traffic
- VPC flow logging enabled for all VPCs

Each control has a severity (Critical, High, Medium, Low) and a remediation procedure. Security Hub tracks the pass/fail status of each control across all accounts in your AWS Organization.

---

## Custom Security Hub Controls

The standard CIS benchmark does not cover organization-specific policies — for example, "all S3 buckets must have a CostCenter tag" or "no EC2 instances may run in us-east-1 without prior approval." Custom controls are implemented as:

1. **AWS Config Rules** — evaluation logic that runs against resource configuration changes
2. **Security Hub custom integration** — findings from Config Rules flow to Security Hub via a Lambda function that translates Config findings to ASFF format

This pattern lets you express any organization policy as a Security Hub control with a consistent finding format, severity, and remediation workflow.

---

## Alerting and Auto-Remediation

Security Hub findings route to Amazon EventBridge, which triggers downstream actions:

**Alerting pattern:**
```
Security Hub finding (Critical)
  → EventBridge rule (severity = CRITICAL)
  → SNS topic
  → Slack webhook Lambda / PagerDuty integration
```

**Auto-remediation pattern:**
```
Security Hub finding (SSH unrestricted inbound)
  → EventBridge rule (controlId = CIS.2.1)
  → Lambda function
  → Removes overpermissive ingress rule from security group
  → Posts remediation confirmation to #security-alerts Slack
```

Auto-remediation is appropriate for high-confidence, low-blast-radius findings — for example, removing an open SSH rule that should never exist. It is not appropriate for findings that require human judgment about business impact.

---

## Lab Exercise

The lab for this chapter walks through:

1. Enabling AWS Security Hub in a test account and reviewing CIS benchmark findings
2. Creating an EventBridge rule that routes Critical findings to a Slack webhook
3. Writing a custom AWS Config Rule for a tag compliance policy
4. Implementing a Lambda auto-remediation function for an open security group rule
5. Generating a Security Hub findings report for a compliance review

See [lab/README.md](lab/README.md) to begin.

---

## Further Reading

- [cloud-security-devsecops: cnapp-integration.md](../../../../cloud-security-devsecops/docs/cnapp-integration.md) — CSPM, CWPP, CIEM, and CNAPP platform selection
- [cloud-security-devsecops: architecture.md](../../../../cloud-security-devsecops/docs/architecture.md) — cloud security reference architecture
- [Chapter 1 — IaC Security Scanning](../ch01-iac-security/README.md) — the pre-deployment counterpart to CSPM
- [compliance-automation-framework: evidence-collection-automation.md](../../../../compliance-automation-framework/docs/evidence-collection-automation.md) — using Security Hub findings as continuous compliance evidence
