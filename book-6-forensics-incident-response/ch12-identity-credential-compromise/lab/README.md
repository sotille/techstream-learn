# Lab 12 — Identity and Credential Compromise Investigation

**Estimated time:** 60–75 minutes
**Difficulty:** Intermediate–Advanced
**Prerequisites:** Familiarity with AWS IAM and CloudTrail; understanding of OIDC federation tokens; completion of Lab 9 or Lab 11 (or equivalent cloud incident response experience)

---

## Objective

By the end of this lab you will be able to:
- Trace the complete lifecycle of a compromised OIDC federation token from issuance to expiry
- Separate legitimate pipeline credential use from attacker activity in IAM audit logs
- Determine blast radius for both short-lived OIDC tokens and long-lived service account keys
- Identify the immediate revocation actions required for each credential type

---

## Exercise 1 — OIDC Token Abuse Investigation (35 minutes)

### Background

On 2024-10-22, Westfield Engineering's security team received an alert: their AWS GuardDuty detected `UnauthorizedAccess:IAMUser/InstanceCredentialExfiltration.OutsideAWS` for the IAM role `github-actions-deploy`. This alert fires when credentials associated with an EC2 instance profile or similar role are used from an IP address outside AWS.

The OIDC token for the `github-actions-deploy` role was issued at 10:00:00 UTC and had a 1-hour lifetime. The following CloudTrail events are available.

### CloudTrail Events (2024-10-22, all UTC)

**Legitimate pipeline activity (source IP: 192.0.2.77 — GitHub Actions runner):**

```
10:00:12  AssumeRoleWithWebIdentity → github-actions-deploy
10:00:44  GetSecretValue → secrets/prod/database-url
10:00:45  GetSecretValue → secrets/prod/redis-url
10:01:02  ECR:GetAuthorizationToken
10:01:15  ECR:BatchGetImage → repo/api-service:v3.1.0
10:08:33  ECS:RegisterTaskDefinition → api-service (revision 47)
10:08:44  ECS:UpdateService → cluster/prod, service/api-service
10:09:02  ECS:DescribeServices → cluster/prod (status check)
10:11:17  ECS:DescribeServices → cluster/prod (status check)
10:12:45  ECS:DescribeServices → cluster/prod (status check, deployment complete)
```

**Suspicious activity (source IP: 45.33.32.156 — external, not GitHub IP range):**

```
10:43:01  AssumeRole → github-actions-deploy (via existing session)
10:43:18  GetCallerIdentity
10:43:22  IAM:ListRoles
10:43:29  IAM:ListPolicies
10:43:47  IAM:GetRolePolicy → github-actions-deploy
10:44:03  STS:GetCallerIdentity
10:44:15  S3:ListBuckets
10:44:28  S3:GetObject → westfield-config-backup/terraform.tfstate
10:44:44  S3:GetObject → westfield-config-backup/vault-keys.json
10:45:02  SecretsManager:ListSecrets
10:45:09  SecretsManager:GetSecretValue → secrets/prod/payment-processor-key
10:45:16  SecretsManager:GetSecretValue → secrets/prod/internal-api-signing-key
10:45:33  IAM:CreateUser → (attempted) → AccessDenied
10:45:44  IAM:AttachUserPolicy → (attempted) → AccessDenied
10:46:02  EC2:DescribeInstances
10:46:09  EC2:DescribeSecurityGroups
10:58:00  (token expiry — no further events from this session)
```

**Questions:**

1. At what time did the attacker begin using the stolen credential, and how much time remained before token expiry? What does this timing suggest about how the token was stolen?

2. The attacker's first action is `AssumeRole` rather than directly using the OIDC-issued session. What does this tell you about the role's trust policy, and what additional risk does it create?

3. The attacker accessed two objects from the `westfield-config-backup` S3 bucket: `terraform.tfstate` and `vault-keys.json`. Explain the specific risk posed by each of these files in an attacker's hands.

4. List all secrets that were successfully accessed by the attacker. For each, describe the likely impact and the immediate remediation action required.

5. Two IAM escalation attempts (`CreateUser`, `AttachUserPolicy`) were blocked by access denial. What does this tell you about the IAM policy on `github-actions-deploy`? Despite the denials, what persistence mechanism might the attacker have achieved through the actions that succeeded?

6. The OIDC token expired at approximately 11:00:12 UTC. Confirm whether all attacker activity ceased at that time. What revocation action was still required even though the token expired?

---

## Exercise 2 — Long-Lived Credential Exposure Investigation (25 minutes)

### Background

A developer at Northbrook Analytics accidentally committed an AWS service account key to a public GitHub repository at 2024-10-15 09:23:00 UTC. The commit was discovered by the security team at 2024-10-15 14:47:00 UTC and the key was immediately revoked. The exposure window is therefore approximately 5 hours and 24 minutes.

The service account (`sa-data-pipeline`) had the following permissions:
- `s3:GetObject`, `s3:PutObject`, `s3:ListBucket` on the `northbrook-analytics-data` bucket
- `glue:StartJobRun`, `glue:GetJobRun` on all Glue jobs
- `secretsmanager:GetSecretValue` on `data-pipeline/*` secrets

### CloudTrail Events for `sa-data-pipeline` (2024-10-15, UTC)

**Normal pipeline activity (source IP: 10.0.3.0/24 — internal VPC):**

```
09:00-09:23  Regular Glue job execution (GetJobRun, S3 reads/writes) — approximately 40 events
```

**Post-exposure activity:**

```
09:31:14  AssumeRole (source IP: 104.21.14.89)
09:31:22  S3:ListBuckets (source IP: 104.21.14.89)
09:31:33  S3:ListObjectsV2 → northbrook-analytics-data (source IP: 104.21.14.89)
09:32:01  S3:GetObject → northbrook-analytics-data/raw/customers-2024-10.parquet (source IP: 104.21.14.89)
09:32:19  S3:GetObject → northbrook-analytics-data/raw/transactions-2024-10.parquet (source IP: 104.21.14.89)
09:32:44  S3:GetObject → northbrook-analytics-data/processed/revenue-report-Q3.csv (source IP: 104.21.14.89)
09:33:10  SecretsManager:GetSecretValue → data-pipeline/snowflake-credentials (source IP: 104.21.14.89)
09:33:24  Glue:StartJobRun → customer-export-job (source IP: 104.21.14.89)
09:33:41  Glue:GetJobRun → customer-export-job (source IP: 104.21.14.89)
10:01:17  Glue:GetJobRun → customer-export-job (source IP: 104.21.14.89)
10:28:44  Glue:GetJobRun → customer-export-job (source IP: 104.21.14.89)
10:29:01  S3:GetObject → northbrook-analytics-data/exports/customer-export-20241015.csv (source IP: 104.21.14.89)
... (no further events from external IP after 10:29 UTC)
```

**Questions:**

1. The key was committed at 09:23:00 UTC and the first external API call occurs at 09:31:14 UTC — approximately 8 minutes later. What does this suggest about how the attacker discovered the exposed key?

2. The attacker started a Glue job (`customer-export-job`) and then polled its status before downloading the output. What does this tell you about the attacker's intent and sophistication?

3. Based on the CloudTrail evidence, what specific data was accessed or exfiltrated? List each item, the timestamp, and the sensitivity classification you would apply.

4. The attacker accessed `data-pipeline/snowflake-credentials` from Secrets Manager. This is a second-order credential exposure. What additional investigation steps are now required as a result of this access?

5. The key was revoked at 14:47:00 UTC. The last attacker activity was at 10:29:01 UTC. What does the 4-hour gap between last attacker activity and revocation mean for the investigation, and what risk remains after key revocation?

6. A long-lived key provides persistent access. An OIDC token provides time-limited access. Based on this scenario, make the case for migrating from long-lived service account keys to OIDC federation for all pipeline machine identities.

---

## Summary

Identity and credential compromise investigations are distinguished by their time-sensitive nature. OIDC tokens provide a natural time limit but can enable further compromise if the role allows `AssumeRole` chaining. Long-lived keys provide persistent access and remain valid until explicitly revoked — meaning a key committed to a public repository continues to be usable for hours or days before discovery and revocation.

The investigation methodology is consistent across both types: separate legitimate from attacker activity by source IP, enumerate every resource accessed, identify second-order credential exposures, and produce a complete blast radius before beginning remediation.

---

## Further Reading

- Chapter 12 (in the book): Identity and Credential Compromise Investigation — full methodology and evidence procedures
- Chapter 5: Immutable Audit Trails — ensuring CloudTrail is tamper-resistant before it is needed
- [AWS CloudTrail documentation](https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-concepts.html)
- [GitHub secret scanning](https://docs.github.com/en/code-security/secret-scanning/about-secret-scanning) — automated detection of committed credentials
