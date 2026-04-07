# Chapter 2 — Running a TDMM Maturity Assessment

## What You Will Learn

You cannot improve what you cannot measure. The Techstream DevSecOps Maturity Model (TDMM) provides a structured, evidence-based framework for assessing where your organization currently stands across eight security domains — and for building a prioritized improvement roadmap from those results.

By the end of this chapter, you will understand:

- The structure of the TDMM: 8 domains, 5 maturity levels, and what each level requires
- How to run a 2-hour TDMM quick-start assessment with a cross-functional team
- How to interpret your results and identify which domains to prioritize
- How to translate assessment results into a 12–18 month improvement roadmap
- How to present maturity results to executive stakeholders without overstating or understating risk

## Why It Matters

Organizations that invest in DevSecOps without a baseline assessment often make the same mistakes: buying tools that address the wrong problems, deploying security controls in the wrong order, and failing to measure whether their investment is working. The TDMM provides the baseline that makes investment decisions evidence-driven.

A maturity assessment also creates a common language between security, engineering, and business leadership. Instead of "we need to improve our security" (which means different things to different people), a TDMM assessment produces: "We are at Level 2 in 4 domains and Level 1 in 3 domains. Reaching Level 3 across all domains is a 12-month program that requires X in tooling and Y in engineering time." That specificity is what makes executive sponsorship possible.

## The TDMM Structure

The TDMM evaluates security capability across 8 domains:

| Domain | What It Measures |
|---|---|
| **1. Source Code Security** | Pre-commit hooks, secrets detection, code review enforcement, branch protection |
| **2. Build and CI Pipeline Security** | Pipeline hardening, dependency scanning, SAST integration, artifact signing |
| **3. Artifact and Registry Security** | Image scanning, signing, promotion gates, registry access controls |
| **4. Infrastructure Security** | IaC scanning, cloud posture management, configuration drift detection |
| **5. Secrets Management** | Secret classification, injection patterns, rotation automation, vault adoption |
| **6. Identity and Access Management** | Pipeline IAM, OIDC adoption, least privilege, privileged access management |
| **7. Runtime Security and Observability** | Container runtime protection, log aggregation, anomaly detection, incident response |
| **8. Compliance and Governance** | Policy as code, audit automation, evidence collection, regulatory alignment |

Each domain is assessed across 5 maturity levels:

| Level | Name | Description |
|---|---|---|
| **1** | Initial (Ad Hoc) | Security is reactive and unstructured; no defined process |
| **2** | Managed (Repeatable) | Basic practices formalized; applied inconsistently across teams |
| **3** | Defined (Standardized) | Security consistently integrated across the SDLC; measurable |
| **4** | Quantitatively Managed (Measured) | Security driven by metrics and risk quantification; data-driven decisions |
| **5** | Optimizing (Continuous Improvement) | Industry-leading program; security improvements are systematic and proactive |

**Most organizations beginning a DevSecOps program are at Level 1–2 across most domains.** Reaching Level 3 consistently is the primary target for a 12–18 month improvement program.

## Assessment Methodology

A TDMM assessment is not a solo exercise — it requires input from representatives of security, engineering, and operations to produce an accurate, consensus-based result. The 2-hour quick-start format:

1. **Pre-work (30 min)**: Distribute the assessment scorecard to participants. Each person independently scores their perception of each domain on the 1–5 scale before the session.
2. **Calibration (30 min)**: Review the level definitions as a group. Establish shared understanding of what each level requires.
3. **Scoring session (60 min)**: Work through each domain. Where scores differ, discuss until consensus is reached or the gap is documented as a risk/uncertainty.
4. **Output**: A scorecard with consensus scores per domain, supporting evidence, and initial gap identification.

## Interpreting Results

After scoring, look for three patterns:

1. **Foundation gaps**: Domains at Level 1 that block progress in other domains (typically: Secrets Management, Pipeline Security). Fix these first.
2. **Cluster gaps**: Multiple domains at Level 2 that all require similar capabilities (often tooling, training, or process changes). These are candidates for a single program.
3. **Isolated gaps**: Individual domains significantly lower than others. These may indicate team-specific issues rather than organization-wide ones.

## Framework Reference

This chapter is based on:

- [DevSecOps Maturity Model: Implementation Guide](../../devsecops-maturity-model/docs/implementation.md)
- [Assessment Scorecard](../../devsecops-maturity-model/docs/assessment-scorecard.md)
- [Remediation Playbooks](../../devsecops-maturity-model/docs/remediation-playbooks.md)

## Lab

See [lab/README.md](lab/README.md) for the hands-on exercise: **Running a TDMM Self-Assessment and Building a Roadmap**.
