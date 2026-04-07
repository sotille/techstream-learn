# Techstream Learn

Hands-on labs, exercises, and examples companion to the Techstream Book Series.

Each folder maps to a book volume and chapter. Labs are designed to be completed
in a local development environment or cloud shell.

## Structure

```
techstream-learn/
├── book-1-foundations/          ← Vol 1: DevSecOps Foundations & Transformation
├── book-2-cicd-supply-chain/    ← Vol 2: Securing CI/CD & the Software Supply Chain
├── book-3-cloud-security/       ← Vol 3: Cloud-Native Security for DevSecOps
└── book-4-release-governance/   ← Vol 4: Release Engineering & Governance
```

## How to Use

1. Start with the book chapter referenced in each lab's README
2. Follow the lab instructions in `lab/README.md`
3. Compare your implementation with the enterprise reference in
   [techstream-frameworks](https://github.com/sotille/techstream-frameworks)

## Recommended Learning Paths

Use one of these paths based on your role and primary goal. Each path lists chapters
in completion order, with the estimated total time.

### Path A — "New to DevSecOps" (Start here)
For engineers or managers beginning a DevSecOps transformation.
**Estimated time:** 5–6 hours across 4 labs

| Order | Chapter | Focus | Time |
|-------|---------|-------|------|
| 1 | [book-1 / ch01-why-devsecops](book-1-foundations/ch01-why-devsecops/) | Build the business case for DevSecOps adoption | 30–45 min |
| 2 | [book-1 / ch02-maturity-assessment](book-1-foundations/ch02-maturity-assessment/) | Assess your organization with the TDMM model | 60–90 min |
| 3 | [book-2 / ch01-pipeline-threats](book-2-cicd-supply-chain/ch01-pipeline-threats/) | Understand what attackers target in CI/CD pipelines | 45–60 min |
| 4 | [book-2 / ch03-oidc-keyless](book-2-cicd-supply-chain/ch03-oidc-keyless/) | Replace long-lived CI/CD credentials with OIDC federation | 50–60 min |

---

### Path B — "Securing the Pipeline" (CI/CD focus)
For DevOps engineers hardening existing pipelines and supply chains.
**Estimated time:** 3.5–4.5 hours across 4 labs

| Order | Chapter | Focus | Time |
|-------|---------|-------|------|
| 1 | [book-2 / ch01-pipeline-threats](book-2-cicd-supply-chain/ch01-pipeline-threats/) | Threat model your existing pipeline with STRIDE | 45–60 min |
| 2 | [book-2 / ch03-oidc-keyless](book-2-cicd-supply-chain/ch03-oidc-keyless/) | Eliminate long-lived credentials with OIDC federation | 50–60 min |
| 3 | [book-2 / ch02-slsa-sbom](book-2-cicd-supply-chain/ch02-slsa-sbom/) | Generate and sign SBOMs; implement SLSA provenance | 45–55 min |
| 4 | [book-2 / ch04-artifact-integrity](book-2-cicd-supply-chain/ch04-artifact-integrity/) | Sign artifacts with Cosign; enforce promotion gates | 50–60 min |

---

### Path C — "Cloud Security Practitioner"
For cloud engineers and security architects working on AWS/Azure/GCP environments.
**Estimated time:** 5–6 hours across 4 labs

| Order | Chapter | Focus | Time |
|-------|---------|-------|------|
| 1 | [book-3 / ch01-iac-security](book-3-cloud-security/ch01-iac-security/) | Scan Terraform for cloud misconfigurations with Checkov | 50–60 min |
| 2 | [book-3 / ch02-cloud-identity-threats](book-3-cloud-security/ch02-cloud-identity-threats/) | Audit IAM, detect privilege escalation paths, enforce IMDSv2 | 50–65 min |
| 3 | [book-3 / ch03-kubernetes-hardening](book-3-cloud-security/ch03-kubernetes-hardening/) | CIS benchmark, Pod Security Standards, network policies | 55–70 min |
| 4 | [book-3 / ch04-serverless-security](book-3-cloud-security/ch04-serverless-security/) | Lambda IAM hardening, SCA for function packages, Checkov scan | 45–60 min |

---

### Path D — "Release Engineering & Governance"
For platform engineers and release managers implementing progressive delivery.
**Estimated time:** 2–2.5 hours across 2 labs

| Order | Chapter | Focus | Time |
|-------|---------|-------|------|
| 1 | [book-4 / ch01-blue-green-deployment](book-4-release-governance/ch01-blue-green-deployment/) | Implement blue-green traffic switching in Kubernetes | 45–55 min |
| 2 | [book-4 / ch02-canary-releases](book-4-release-governance/ch02-canary-releases/) | Progressive delivery with Argo Rollouts and quality gates | 55–65 min |

---

## Available Chapters

### Book 1 — DevSecOps Foundations & Transformation

| Chapter | Topic |
|---------|-------|
| [ch01-why-devsecops](book-1-foundations/ch01-why-devsecops/) | The business case and ROI model for DevSecOps |
| [ch02-maturity-assessment](book-1-foundations/ch02-maturity-assessment/) | TDMM self-assessment and roadmap building |

### Book 2 — Securing CI/CD & the Software Supply Chain

| Chapter | Topic |
|---------|-------|
| [ch01-pipeline-threats](book-2-cicd-supply-chain/ch01-pipeline-threats/) | STRIDE threat modeling for CI/CD pipelines |
| [ch02-slsa-sbom](book-2-cicd-supply-chain/ch02-slsa-sbom/) | SLSA levels, SBOM generation, Cosign attestation |
| [ch03-oidc-keyless](book-2-cicd-supply-chain/ch03-oidc-keyless/) | OIDC federation across AWS, Azure, and GCP |
| [ch04-artifact-integrity](book-2-cicd-supply-chain/ch04-artifact-integrity/) | Cosign signing, SLSA provenance, promotion gates |

### Book 3 — Cloud-Native Security for DevSecOps

| Chapter | Topic |
|---------|-------|
| [ch01-iac-security](book-3-cloud-security/ch01-iac-security/) | Checkov IaC scanning, custom policies, compliance reports |
| [ch02-cloud-identity-threats](book-3-cloud-security/ch02-cloud-identity-threats/) | IAM privilege escalation, IMDSv2, CloudTrail analysis |
| [ch03-kubernetes-hardening](book-3-cloud-security/ch03-kubernetes-hardening/) | CIS Benchmark, Pod Security Standards, Kyverno policies |
| [ch04-serverless-security](book-3-cloud-security/ch04-serverless-security/) | Lambda IAM hardening, SCA for function packages, event injection threats |

### Book 4 — Release Engineering & DevSecOps Governance

| Chapter | Topic |
|---------|-------|
| [ch01-blue-green-deployment](book-4-release-governance/ch01-blue-green-deployment/) | Blue-green traffic switching, rollback, audit trail |
| [ch02-canary-releases](book-4-release-governance/ch02-canary-releases/) | Argo Rollouts, traffic weights, automated rollback |

---

## Prerequisites

- Docker or Podman
- A GitHub or GitLab account (for CI/CD labs)
- Basic familiarity with YAML and command-line tools
- Cloud provider account (AWS, Azure, or GCP) for cloud security labs (book-3)
- `kubectl` and Helm 3 for Kubernetes labs (book-3/ch03, book-4)

## License

Apache 2.0 — see LICENSE
