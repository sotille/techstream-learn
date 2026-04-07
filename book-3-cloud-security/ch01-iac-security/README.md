# Chapter 1 — IaC Security: Scanning Terraform for Cloud Misconfigurations

**Volume:** Book 3 — Cloud-Native Security for DevSecOps
**Framework reference:** [cloud-security-devsecops](../../../../cloud-security-devsecops/docs/architecture.md) | [compliance-automation-framework](../../../../compliance-automation-framework/docs/framework.md)

---

## What You Will Learn

Infrastructure as Code (IaC) is how cloud resources are defined and provisioned. Terraform, Bicep, CloudFormation, and Pulumi all encode the configuration of your cloud environment in files that are committed to version control and applied by pipelines. This is a significant security improvement over manual cloud console operations — but it creates a new risk: every IaC configuration error becomes a production cloud misconfiguration at deployment time.

Cloud misconfiguration remains the leading cause of cloud security incidents. Public S3 buckets, overly permissive security groups, unencrypted storage, and absent audit logging are not firewall bypass attacks — they are operational errors in IaC files that could have been detected before `terraform apply` was ever run.

This chapter covers:

1. **The misconfiguration threat surface** — which IaC mistakes consistently lead to cloud breaches
2. **Static analysis for IaC** — how tools like Checkov analyze Terraform before deployment
3. **Pipeline integration** — embedding IaC security scanning as a mandatory pre-deployment gate
4. **Policy-as-code** — defining custom organizational controls in addition to built-in rulesets

---

## Why Cloud Misconfigurations Are the Dominant Attack Surface

The 2019 Capital One breach — the most studied cloud security incident of the decade — was enabled by two misconfigurations: an EC2 instance profile with excessive IAM permissions, and a misconfigured WAF. No novel exploit technique was required. The attacker used a Server-Side Request Forgery (SSRF) vulnerability in an application to query the EC2 metadata service, retrieved credentials from the IAM role attached to the instance, and used those credentials to access S3 buckets containing sensitive data.

Both misconfigurations would have been flagged by modern IaC scanning tools:
- **IAM over-permissioning**: Checkov rule `CKV_AWS_40` and `CKV2_AWS_56` flag roles with admin access or `*` resource wildcards
- **WAF association**: Checkov rule `CKV_AWS_86` flags Application Load Balancers without WAF association

Shifting IaC security left — scanning before deployment — converts what would have been a runtime vulnerability into a pull request comment and a blocked pipeline.

---

## Tools Landscape

### Checkov (Bridgecrew/Palo Alto Networks)

Checkov is the most widely adopted open-source IaC security scanner. It supports Terraform, CloudFormation, Kubernetes manifests, Dockerfiles, Bicep, ARM templates, and Helm charts. Checkov ships with 1,000+ built-in rules covering:

- AWS, Azure, and GCP misconfigurations
- CIS Benchmarks for cloud platforms
- GDPR, HIPAA, PCI-DSS, SOC 2, and NIST 800-53 mappings
- Custom policies in Python or YAML

**Key differentiator:** Checkov maps every rule to compliance frameworks, enabling organizations to run a compliance-scoped scan and report directly to auditors.

### Trivy (Aqua Security)

Trivy also supports IaC scanning (Terraform, CloudFormation, Kubernetes) in addition to container images. Its advantage is a single tool for both container and IaC security, simplifying pipeline integration. Trivy IaC output includes misconfig severity, affected resources, and remediation guidance.

### KICS (Checkmarx)

KICS (Keeping Infrastructure as Code Secure) is an open-source scanner supporting 15+ IaC platforms. It is particularly strong for multi-platform environments where Terraform, Ansible, and CloudFormation coexist.

### tfsec / Terrascan

tfsec (now merged into Trivy as the terraform scanner) and Terrascan are Terraform-specific scanners. They offer deep Terraform module analysis and good local developer experience. For CI/CD pipeline integration, Trivy or Checkov typically provide better coverage across IaC types.

---

## How IaC Scanning Works

IaC scanners perform static analysis on resource declarations without executing them. For Terraform, this means:

1. **Parse the HCL**: The scanner reads `.tf` files and builds a resource model
2. **Evaluate rules**: Each resource is checked against a ruleset (e.g., "S3 bucket should have `server_side_encryption_configuration` block")
3. **Report findings**: Failing resources are reported with rule ID, severity, file path, line number, and remediation guidance
4. **Exit with non-zero code**: In pipeline mode, any failed rule at or above the configured severity threshold causes a non-zero exit, blocking the pipeline

Importantly, IaC scanning works *without* cloud provider access — the scanner reads the code, not the deployed infrastructure. This makes it fast (sub-second for most scans) and safe to run on every commit.

---

## Limitations of IaC Scanning

IaC scanning finds what it can see in the static configuration. It cannot detect:

- **Runtime drift**: Resources modified directly in the cloud console after deployment (use CSPM for this)
- **Dynamic configurations**: Values resolved at apply time from data sources or external systems
- **Cross-resource attack paths**: A misconfigured IAM role that enables privilege escalation through multiple resources (use CNAPP attack path analysis for this)

IaC scanning is a prevention control. CSPM is a detection control for the same class of problems. Both are required in a mature cloud security program.

---

## Lab Exercise

The lab for this chapter walks through:
1. Installing and running Checkov locally against a Terraform module with intentional misconfigurations
2. Interpreting Checkov output — understanding rule IDs, severity, and remediation
3. Integrating Checkov into a GitHub Actions pipeline as a mandatory gate
4. Writing a custom Checkov policy for an organization-specific control
5. Running a compliance-scoped scan and generating a SOC 2 / CIS Benchmark report

See [lab/README.md](lab/README.md) to begin.

---

## Key Controls Covered in This Chapter

| Misconfiguration Class | Example | Detection |
|------------------------|---------|-----------|
| Public cloud storage | S3 bucket with public ACL | `CKV_AWS_20`, `CKV2_AWS_6` |
| Encryption gaps | RDS without encryption at rest | `CKV_AWS_17` |
| IAM over-permission | IAM role with `*` resource | `CKV_AWS_40` |
| Logging disabled | CloudTrail not enabled | `CKV2_AWS_10` |
| Network exposure | Security group with `0.0.0.0/0` ingress | `CKV_AWS_24`, `CKV_AWS_25` |
| Secrets in config | Hardcoded credentials in TF variables | `CKV_SECRET_*` |
| MFA not required | IAM policies not requiring MFA | `CKV_AWS_9` |

---

## Further Reading

- [cloud-security-devsecops: zero-trust-architecture.md](../../../../cloud-security-devsecops/docs/zero-trust-architecture.md) — zero trust controls IaC must enforce
- [compliance-automation-framework: regulatory-controls-matrix.md](../../../../compliance-automation-framework/docs/regulatory-controls-matrix.md) — compliance framework mapping for IaC controls
- Checkov documentation: `checkov.io`
- CIS Benchmarks for AWS, Azure, GCP (free at `cisecurity.org`)
