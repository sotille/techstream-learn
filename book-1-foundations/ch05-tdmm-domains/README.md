# Chapter 5 — The TDMM: 8 Domains, 5 Levels

## What You Will Learn

This chapter introduces the Techstream DevSecOps Maturity Model (TDMM) — its structure, the meaning of each domain, and how the five maturity levels describe qualitatively different organizational capabilities rather than arbitrary score thresholds. You will learn to use the TDMM as a direction indicator: a shared language for discussing where a DevSecOps program is and where it needs to go, not a compliance score.

## The Structure of the TDMM

The TDMM evaluates DevSecOps practice across 8 domains. Each domain represents a distinct capability area with independent practices, tooling, and organizational dependencies. A strong organization can be at Level 3 in CI/CD Security while remaining at Level 1 in AI & Agentic Security — this is normal and expected as organizations adopt new technologies at different rates.

**Domain 1 — Culture & Organization**
Addresses how security is owned, communicated, and incentivized across engineering and operations teams. Covers security champion programs, security training, and the shift from security-as-gatekeeper to security-as-shared-responsibility. An organization that has deployed excellent tooling but whose engineers view security as someone else's problem is at Level 1–2 in this domain regardless of tool coverage.

**Domain 2 — Security Requirements**
Addresses how security properties are identified and incorporated at the design phase. Covers threat modeling, abuse case analysis, security user stories, and privacy requirements. Most organizations at Level 1 discover security requirements when an audit finds a missing control or a penetration tester finds a vulnerability. Level 3+ organizations identify security requirements before implementation begins, on every significant change.

**Domain 3 — Secure Development**
Addresses the security quality of code produced by engineering teams. Covers SAST, pre-commit hooks, IDE security plugins, secure coding standards, and developer feedback loops. Distinguishes between having a tool and having a tool that produces findings that engineers act on.

**Domain 4 — CI/CD Security**
Addresses the security of the pipeline itself and the controls applied during build, test, and deployment. Covers ephemeral build environments, secrets management, OIDC keyless authentication, artifact signing, SBOM generation, and pipeline access control. At Level 1, pipelines are functional but treat security as optional. At Level 4, the pipeline itself is a security control: unattestad artifacts cannot reach production.

**Domain 5 — Cloud Security**
Addresses security in cloud infrastructure, including identity and access management, workload security, infrastructure as code validation, runtime detection, and CSPM. Covers AWS, Azure, and GCP environments and Kubernetes workloads. An organization with strong CI/CD Security (Domain 4) may have weak Cloud Security (Domain 5) if its platform team has not applied equivalent rigor to the cloud environment that pipelines deploy into.

**Domain 6 — Compliance Automation**
Addresses how compliance obligations are met — whether through manual evidence collection and periodic audits, or through automated evidence generation, continuous control monitoring, and evergreen audit readiness. At Level 1, compliance is episodic and expensive. At Level 4+, the compliance evidence package for any in-scope framework is assembling itself continuously.

**Domain 7 — Incident Response & Forensics**
Addresses the organization's capability to detect, investigate, and recover from security incidents in software delivery systems. Covers detection tooling, forensic evidence infrastructure, incident playbooks, tabletop exercises, and the specialized domain of agent forensics (investigating incidents involving AI components). Organizations discover most of their Domain 7 deficiencies during actual incidents, not during assessment.

**Domain 8 — AI & Agentic Security**
Addresses security in systems that incorporate AI components — coding assistants, AI-powered code review, autonomous pipeline agents, and AI-driven operations. This domain is newest in the TDMM and most organizations are at Level 1 or early Level 2. Level 1 (AI-Naive) means AI is being used but without systematic security controls. Level 2 (AI-Aware) means the organization has inventoried its AI usage and has basic policies. Level 5 (AI-Secure) means the organization applies the full Techstream AI security framework including agent authorization, behavioral baselines, and forensic readiness.

## The Five Maturity Levels

Maturity levels describe how an organization relates to its security practices — not simply which tools are deployed.

**Level 1 — Initial (Ad Hoc)**
Security exists as individual effort, not organizational capability. Controls are deployed inconsistently. Security findings are not systematically tracked or remediated. Compliance is achieved through heroic pre-audit efforts, not repeatable process. The organization does not know its baseline security posture.

**Level 2 — Managed (Repeatable)**
Basic processes are established and followed consistently. The organization knows what controls it has and has evidence that they work. Security findings are tracked to closure. Teams understand their security responsibilities. The organization can pass an audit without a pre-audit sprint (barely).

**Level 3 — Defined (Standardized)**
Security practices are documented, standardized across teams, and applied consistently. Automation handles a large portion of security testing, evidence collection, and policy enforcement. Security is integrated into developer workflows rather than applied at the end of the delivery process. The organization can describe its security posture accurately at any time.

**Level 4 — Quantitatively Managed (Measured)**
Security outcomes are measured quantitatively and used to drive decisions. The organization tracks metrics for each TDMM domain and uses them to identify regressions, prioritize improvements, and communicate progress. Changes to security controls are evaluated against their expected effect on measured outcomes. The organization can answer "are we improving?" with data.

**Level 5 — Optimizing (Continuous Improvement)**
The organization systematically identifies and implements improvements across all domains. Security practices evolve proactively as the threat landscape, technology stack, and regulatory environment change. Tooling, process, and culture improvements are continuous and institutionalized. The organization contributes improvements back to the community (open-source tools, published research, community participation).

## TDMM vs. Other Maturity Models

The TDMM is calibrated for organizations operating in cloud-native, DevOps-oriented software delivery environments. It differs from other frameworks:

**vs. BSIMM (Building Security In Maturity Model):** BSIMM is observational — it describes what real organizations do, not what they should do. TDMM is prescriptive — it defines specific capability targets per level. BSIMM is better for benchmarking; TDMM is better for driving improvement programs.

**vs. OWASP SAMM (Software Assurance Maturity Model):** SAMM covers software security practices comprehensively but predates the DevOps era. It requires adaptation for CI/CD, cloud, and AI security contexts. TDMM is designed for these environments natively. SAMM and TDMM can be used together — SAMM for application security depth, TDMM for DevSecOps breadth.

**vs. NIST CSF:** NIST CSF is a risk management framework, not a maturity model. It identifies functions (Identify, Protect, Detect, Respond, Recover) but does not prescribe implementation or progression. TDMM maps to NIST CSF functions but provides implementation-level guidance.

## Practical Implications

A TDMM assessment is only as useful as the improvement program it drives. Before starting an assessment:

1. **Confirm leadership buy-in.** A maturity assessment that produces a backlog no one is authorized to act on wastes everyone's time.
2. **Define scope explicitly.** Which teams, products, and environments are in scope? Scope changes between assessments invalidate trend comparisons.
3. **Use a cross-team assessment panel.** Teams that assess themselves tend to overestimate their own maturity. Teams that assess each other produce more accurate results.
4. **Start with the gap, not the score.** The score is not the goal. The gap between current and next-level requirements is the actionable output.

## What You Will Practice

This chapter's lab exercises apply the TDMM to a described organization. You will:

- Map the organization's described practices to TDMM domains and levels
- Identify the most significant gaps preventing advancement to the next level in each domain
- Prioritize improvement actions using the gap-by-impact framework
- Draft a one-quarter improvement plan targeting the two domains with the highest improvement return on investment

## Lab

See [lab/README.md](lab/README.md) for the hands-on domain mapping and gap analysis exercise.
