# Changelog

All notable changes to the Techstream Learning Companion are documented here.
Format: `[version] — [date] — [summary of changes]`

---

## [Unreleased]

- [2026-04-07] Created book-3-cloud-security/ch04-serverless-security/ — chapter overview covering serverless threat model (event injection, IAM over-permissioning, dependency vulnerabilities, IMDS exposure), CIS Lambda Benchmark alignment, and tool landscape (Checkov, Grype, Falco, IAM Access Analyzer); includes full lab with Terraform misconfigured/hardened examples, SCA exercise using Grype on Lambda ZIP packages, and GitHub Actions CI workflow; 6 example files across terraform/ and github-actions/
- [2026-04-07] Added book-1-foundations/ch01-why-devsecops/lab/examples/ — three files: defect-cost-model-template.csv (hypothetical baseline with 6 detection stages), defect-cost-model-target-state.csv (80% shift-left projection showing ~$1M annual ROI for 200-person org), and business-case-template.md (executive presentation paragraph template with filled example)
- [2026-04-07] Added book-1-foundations/ch02-maturity-assessment/lab/examples/ — two files: tdmm-assessment-scorecard.csv (blank assessment template for all 8 TDMM domains with multi-participant scoring), tdmm-sample-assessment-acme-corp.md (complete worked example for 350-person hypothetical org including divergence analysis, top 3 priorities, and 90-day roadmap)
- [2026-04-07] Added book-3-cloud-security/ch01-iac-security/lab/examples/ — four files across terraform/ and github-actions/: main-vulnerable.tf (6 annotated misconfigurations with Checkov rule IDs), main-hardened.tf (full remediation with Secrets Manager integration), check_required_tags.py (custom Checkov policy enforcing Techstream tagging standard), iac-security.yml (GitHub Actions workflow for Terraform + GHA scanning with SARIF upload)
- [2026-04-07] Added book-4-release-governance/ch01-blue-green-deployment/lab/examples/ — four files: blue-deployment.yaml, green-deployment.yaml, webapp-service.yaml (with commented traffic-switch commands), switch-traffic.sh (automation script with smoke test → switch → verify sequence, --dry-run and --cleanup flags)
- [2026-04-07] Created book-3-cloud-security/ch02-cloud-identity-threats/ — chapter overview and lab covering IAM privilege escalation analysis (Cloudsplaining), IMDSv2 enforcement with Terraform+Checkov, CloudTrail credential theft trace, and ABAC IAM policy design; includes Terraform and JSON example files
- [2026-04-07] Created book-3-cloud-security/ch03-kubernetes-hardening/ — chapter overview and lab covering kube-bench CIS Benchmark auditing, Pod Security Standards (restricted profile), default-deny network policies, External Secrets Operator, and Kyverno registry admission policies; includes 7 example YAML/JSON files
- [2026-04-07] Created book-4-release-governance/ch02-canary-releases/ — chapter overview and Argo Rollouts lab covering progressive traffic shifting, AnalysisTemplate quality gates, automatic rollback simulation, and deployment strategy decision framework; includes 5 example YAML files
- [2026-04-07] Added book-2-cicd-supply-chain/ch03-oidc-keyless/lab/examples/aws-oidc-trust-policy.json — AWS IAM trust policy template for GitHub Actions OIDC federation (completes multi-cloud coverage alongside existing Azure and GCP examples)
- [2026-04-07] Added book-2-cicd-supply-chain/ch03-oidc-keyless/lab/examples/aws-oidc-setup.sh — shell script for creating AWS OIDC identity provider and federated IAM role (Track A companion, mirrors Azure and GCP setup scripts)
- [2026-04-07] Added book-2-cicd-supply-chain/ch02-slsa-sbom/lab/examples/example-sbom-cyclonedx.json — annotated CycloneDX 1.4 SBOM example with realistic package entries and embedded vulnerability context
- [2026-04-07] Added book-2-cicd-supply-chain/ch02-slsa-sbom/lab/examples/example-sbom-spdx.json — annotated SPDX 2.3 SBOM example in JSON format for format comparison exercises
- [2026-04-07] Added book-2-cicd-supply-chain/ch01-pipeline-threats/lab/examples/github-actions-pipeline-vulnerable.yml — annotated vulnerable pipeline with STRIDE threat categories for each issue
- [2026-04-07] Added book-2-cicd-supply-chain/ch01-pipeline-threats/lab/examples/github-actions-pipeline-hardened.yml — hardened pipeline with annotated mitigations and STRIDE control mapping table
- [2026-04-07] Updated book-2-cicd-supply-chain/ch01-pipeline-threats/lab/README.md — added expected output reference section (trust boundary inventory table and risk scoring table for example pipeline)
- [2026-04-07] Updated README.md — added four recommended learning paths (A–D) for different roles, updated chapter index table with all 11 available chapters
- [2026-04-07] Created book-2-cicd-supply-chain/ch03-oidc-keyless/lab/examples/azure-oidc-setup.sh — complete Azure AD app registration and federated credential setup for GitHub Actions OIDC (Track B companion)
- [2026-04-07] Created book-2-cicd-supply-chain/ch03-oidc-keyless/lab/examples/gcp-oidc-setup.sh — GCP Workload Identity Federation setup for GitHub Actions OIDC (Track C companion)
- [2026-04-07] Created book-2-cicd-supply-chain/ch04-artifact-integrity/ — chapter overview and lab for Cosign keyless signing, SLSA provenance generation, and deployment signature verification gates
- [2026-04-07] Created book-3-cloud-security/ch01-iac-security/ — chapter overview and Checkov lab covering IaC misconfiguration scanning, CI/CD integration, custom policies, and compliance-scoped reporting
- [2026-04-07] Created book-4-release-governance/ch01-blue-green-deployment/ — chapter overview and Kubernetes blue-green deployment lab with atomic traffic switching, smoke test gates, and rollback exercises

## [1.0.0] — 2024-01-15

- Initial repository structure: book-1-foundations/, book-2-cicd-supply-chain/, book-3-cloud-security/, book-4-release-governance/
- book-1-foundations/ch01-why-devsecops/ — chapter overview and DevSecOps foundations lab
- book-1-foundations/ch02-maturity-assessment/ — chapter overview and TDMM maturity assessment lab
- book-2-cicd-supply-chain/ch01-pipeline-threats/ — chapter overview and STRIDE threat modeling lab with GitHub Actions example
- book-2-cicd-supply-chain/ch02-slsa-sbom/ — chapter overview and SBOM generation lab with CycloneDX pipeline example
- book-2-cicd-supply-chain/ch03-oidc-keyless/ — chapter overview and OIDC federation lab (AWS Track A)
- Apache 2.0 license
