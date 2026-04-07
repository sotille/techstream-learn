# Chapter 2 — Cloud Identity Threats: IAM Misconfiguration and Credential Abuse

**Volume:** Book 3 — Cloud-Native Security for DevSecOps
**Framework reference:** [cloud-security-devsecops](../../../../cloud-security-devsecops/docs/architecture.md) | [cloud-security-devsecops: zero-trust-architecture.md](../../../../cloud-security-devsecops/docs/zero-trust-architecture.md)

---

## What You Will Learn

Cloud identity is the primary attack surface in modern cloud environments. Unlike traditional perimeter attacks, cloud breaches rarely require exploiting a software vulnerability. They require only one thing: valid credentials with excessive permissions.

The 2019 Capital One breach was enabled by an IAM role with overly broad permissions — not an unpatched vulnerability. The 2022 LastPass breach began with a compromised developer machine that had cloud access. In each case, the attacker obtained legitimate credentials and the cloud control plane could not distinguish them from an authorized user.

This chapter covers:

1. **The cloud identity attack surface** — how IAM roles, service accounts, and instance metadata create exploitable paths
2. **Credential theft vectors** — SSRF, metadata service abuse, environment variable leakage, and CI/CD secrets exfiltration
3. **IAM privilege escalation** — how limited permissions can be chained to achieve full administrative access
4. **Least-privilege design** — structuring IAM policies to contain blast radius without impeding engineering velocity
5. **Detective controls** — CloudTrail, Azure Activity Logs, and GCP Audit Logs as the data source for identity-based threat detection

---

## The Cloud Identity Problem

Traditional enterprise security controlled access at the network perimeter. Cloud infrastructure inverts this model: resources are intentionally reachable from the internet, and access control is entirely identity-based. This makes IAM design a security-critical function — equivalent in impact to firewall rules in traditional infrastructure.

The three structural problems that create the cloud identity attack surface:

### 1. Credential Proliferation

Cloud workloads accumulate credentials across multiple systems: long-lived IAM access keys in CI/CD secrets, database passwords in environment variables, API tokens hardcoded during prototyping that are never rotated, service account keys downloaded for local testing and then forgotten in repositories.

Each long-lived credential is a persistent attack surface. Any compromise of the system holding the credential grants attacker access for as long as the credential is valid — which in many organizations is indefinitely.

### 2. Over-Permissioned Identities

The fastest path to making infrastructure work is granting broad permissions. Administrator access avoids the friction of debugging permission denials during development. Over time, these overly broad grants accumulate. An IAM role used for a deployment pipeline ends up with permissions it needed once, for a feature that was later removed, that no one remembers to revoke.

The principle of least privilege requires continuous enforcement — not just at initial provisioning, but as workloads evolve and permissions become stale.

### 3. The Instance Metadata Service

Every major cloud platform provides an instance metadata service (IMDS) — an HTTP endpoint reachable from within a compute instance that exposes the instance's IAM credentials. The design intent is workload identity: the application running on the instance can request credentials without storing a secret.

The security problem is SSRF (Server-Side Request Forgery): if an application can be induced to make HTTP requests to attacker-controlled URLs, an attacker can target `http://169.254.169.254` (the IMDS endpoint) and retrieve the instance's cloud credentials.

**The Capital One attack pattern:**
1. Attacker identifies a misconfigured WAF running on an EC2 instance
2. SSRF vulnerability in the WAF allows the attacker to send HTTP requests from the instance
3. Attacker queries `http://169.254.169.254/latest/meta-data/iam/security-credentials/` — this returns the role name attached to the instance
4. Attacker queries the role credentials endpoint and receives temporary AWS access keys
5. Attacker uses those credentials to enumerate and exfiltrate S3 buckets

IMDSv2 (AWS) and equivalent mitigations on Azure and GCP require a session token for metadata access, preventing simple SSRF exploitation of the metadata endpoint. Enabling IMDSv2-only is a mandatory IaC control.

---

## IAM Privilege Escalation Paths

An attacker who obtains limited IAM credentials often does not need administrator access to cause harm. IAM privilege escalation paths chain individual permissions to reach higher-privilege actions.

### Common Escalation Chains

**iam:PassRole + ec2:RunInstances**

If an attacker can pass an IAM role to an EC2 instance (`iam:PassRole`) and launch instances (`ec2:RunInstances`), they can launch a new instance with an administrator role attached. The instance's workload then has administrator credentials, accessible via the metadata service.

**iam:CreatePolicyVersion**

The ability to create a new version of an existing IAM policy allows the attacker to modify the policy to add `"Effect": "Allow", "Action": "*", "Resource": "*"` — full administrator access.

**lambda:CreateFunction + iam:PassRole**

If an attacker can create Lambda functions and pass a high-privilege role, they can create a Lambda with the target role and invoke it to perform privileged actions.

The [Rhino Security Labs IAM Privilege Escalation research](https://rhinosecuritylabs.com/aws/aws-privilege-escalation-methods-mitigation/) catalogued 21 distinct escalation paths in AWS IAM. Similar patterns exist in Azure (role assignments, managed identity abuse) and GCP (service account impersonation, workload identity federation misuse).

### Automated Detection: Cloudsplaining and IAM Access Analyzer

**Cloudsplaining** analyzes IAM policies and identifies privilege escalation paths, data exfiltration risks, and resource exposure.

**AWS IAM Access Analyzer** continuously evaluates IAM policies and resource-based policies for external access and generates findings when public exposure is detected.

**Checkov** IaC rules flag the most dangerous standalone permissions:
- `CKV_AWS_40` — IAM policies attached directly to users (should use groups/roles)
- `CKV2_AWS_56` — IAM roles with administrator access
- `CKV_AWS_274` — IAM policies allowing `*` actions

---

## Least-Privilege Design Principles

### 1. Workload Identity Over Long-Lived Keys

Replace long-lived IAM access keys with workload identity mechanisms:
- **AWS**: IAM roles for EC2, EKS service account annotations (IRSA), OIDC federation for CI/CD
- **Azure**: Managed identities for VMs, AKS pods, and GitHub Actions OIDC federation
- **GCP**: Workload identity federation, service account impersonation

When compute workloads authenticate using their identity (not a stored secret), there is no credential to steal, rotate, or accidentally commit to a repository.

### 2. Permission Boundaries

AWS permission boundaries set the maximum permissions an IAM entity can have, regardless of attached policies. They allow developer teams to self-service IAM role creation without the ability to escalate beyond the boundary.

### 3. Service Control Policies (SCPs)

AWS Organizations SCPs enforce guardrails at the organization or account level — policies that cannot be overridden by individual IAM policies within an account. SCPs are the enforcement mechanism for controls like "no IAM access keys for human users" or "all S3 buckets must have public access blocked."

### 4. Attribute-Based Access Control (ABAC)

ABAC uses tags on both the IAM principal and the resource to make access control decisions dynamically. A pipeline role tagged `team=payments` can be restricted to S3 buckets tagged `team=payments`, without maintaining a list of specific ARNs. ABAC scales gracefully as resource counts grow.

---

## Detective Controls: Audit Logs as Security Data

Prevention controls limit what identities can do. Detective controls identify when something unexpected happens. Cloud audit logs are the primary data source for identity-based threat detection.

| Platform | Audit Log Service | Key Events |
|----------|-------------------|------------|
| AWS | CloudTrail | `ConsoleLogin`, `AssumeRole`, `GetSecretValue`, `CreateUser`, `AttachRolePolicy` |
| Azure | Azure Activity Log / Azure AD Sign-in Logs | Sign-ins, role assignments, policy changes, resource operations |
| GCP | Cloud Audit Logs | `iam.serviceAccounts.actAs`, `setIamPolicy`, `getIamPolicy`, `CreateServiceAccount` |

### Detection Signals for Identity Attacks

| Behavior | CloudTrail / Audit Log Signal |
|----------|-------------------------------|
| Credential theft via metadata service | Unusual `AssumeRole` from unexpected source IP |
| Access key use from new geography | `ConsoleLogin` or API calls from unexpected region |
| Privilege escalation attempt | `iam:CreatePolicyVersion`, `iam:PassRole` by non-admin |
| Lateral movement | `AssumeRole` chains across multiple accounts |
| Data exfiltration probe | High-volume `GetObject` or `ListBuckets` outside normal patterns |

SIEM integration and alerting on these signals is covered in the compliance-automation-framework's continuous monitoring module.

---

## Lab Exercise

The hands-on lab for this chapter covers:
1. Auditing an IAM configuration using Cloudsplaining to identify escalation paths
2. Identifying over-permissioned roles using AWS IAM Access Analyzer findings
3. Enabling IMDSv2-only via Terraform and verifying the Checkov rule passes
4. Tracing a simulated credential theft through CloudTrail logs
5. Writing a least-privilege IAM policy for a deployment pipeline using ABAC

See [lab/README.md](lab/README.md) to begin.

---

## Key Concepts

| Concept | Definition |
|---------|------------|
| SSRF | Server-Side Request Forgery — attacker induces server to make requests to internal endpoints |
| IMDS | Instance Metadata Service — cloud endpoint providing workload credentials at 169.254.169.254 |
| IMDSv2 | Token-required IMDS variant that prevents SSRF-based metadata access |
| IRSA | IAM Roles for Service Accounts — Kubernetes service accounts mapped to IAM roles via OIDC |
| SCP | Service Control Policy — organization-level IAM guardrail that overrides individual account policies |
| ABAC | Attribute-Based Access Control — tag-driven access policy scoping |
| Permission boundary | Maximum permissions cap applied to an IAM entity, regardless of attached policies |

---

## Further Reading

- [cloud-security-devsecops: zero-trust-architecture.md](../../../../cloud-security-devsecops/docs/zero-trust-architecture.md) — zero trust identity controls
- [cloud-security-devsecops: architecture.md](../../../../cloud-security-devsecops/docs/architecture.md) — cloud security architecture with IAM layers
- [secure-ci-cd-reference-architecture: oidc-federation-guide.md](../../../../secure-ci-cd-reference-architecture/docs/oidc-federation-guide.md) — OIDC federation for CI/CD workload identity
- Rhino Security Labs — AWS IAM Privilege Escalation research (`rhinosecuritylabs.com`)
- AWS IAM Access Analyzer documentation (`docs.aws.amazon.com`)
