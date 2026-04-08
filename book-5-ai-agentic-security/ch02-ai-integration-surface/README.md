# Chapter 2 — The AI Integration Surface: Five Layers of Risk

## What You Will Learn

This chapter examines the security risks introduced when AI components — automated code reviewers, vulnerability triage agents, AI-assisted testing tools, and LLM-based security scanners — are embedded in software delivery pipelines. You will learn to identify the attack surface these components create, understand the categories of failure unique to AI systems, and apply a threat model that covers both the AI component itself and the pipeline infrastructure it touches.

## Why This Matters

AI-assisted development tools are being adopted faster than the security frameworks governing them. Organizations deploy AI code reviewers that automatically approve pull requests, AI agents that triage security findings, and AI-generated infrastructure configuration — often without considering how an adversary might exploit the trust those components receive within the pipeline.

The risk is not primarily that AI systems produce wrong answers. The risk is that AI components are granted consequential capabilities — merging code, approving deployments, generating cryptographic artifacts, invoking cloud APIs — and that their decision-making can be manipulated by an adversary who understands how they work.

In 2023 and 2024, public demonstrations showed that AI code reviewers could be fooled into approving code containing backdoors by embedding contradictory instructions in comments, that AI-assisted SBOM generators could be confused about package provenance by crafting misleading package names, and that AI security triage agents could be caused to suppress legitimate findings through adversarially crafted CVE descriptions. The threat is real, the tooling landscape is immature, and the defensive patterns must be understood by any team deploying AI in their delivery process.

## Key Concepts

### The AI Component Trust Problem

When a human reviewer approves a pull request, they accept accountability for that decision. When an AI component does the same, accountability is diffuse: the model developer, the tool integrator, the pipeline operator, and the engineer who merged the AI-approved change all have partial responsibility but clear ownership of none.

More critically, AI components receive implicit trust from the pipeline context they operate in. An AI code reviewer running in a GitHub Actions workflow with `write` permissions to the repository can approve and merge changes just like a human — but unlike a human, it can be manipulated through its inputs. This is the AI equivalent of social engineering, but at machine speed and scale.

### Five AI Component Failure Categories

**1. Adversarial input manipulation (prompt injection)**
An adversary embeds instructions in data the AI processes — commit messages, PR descriptions, code comments, CVE descriptions, SBOM metadata — that override or bypass the component's intended behavior. See Chapter 2 for detailed treatment.

**2. Context window poisoning**
AI components that process large contexts (entire codebases, full PR diffs, combined SBOM + vulnerability reports) are susceptible to important information being displaced by adversarially crafted content that fills the context window with misleading data, causing the model to overlook the actual security-relevant content.

**3. Hallucination under adversarial conditions**
AI models can generate plausible-sounding but false outputs — approving non-existent security controls, citing non-existent CVE mitigations, or declaring a code pattern "safe" based on superficially similar safe patterns in training data. Attackers can craft inputs that increase the likelihood of hallucination in security-critical paths.

**4. Training data contamination**
Organizations fine-tuning models on their own codebases may inadvertently train on code that normalizes insecure patterns, causing the AI to rate security-relevant code patterns as "normal" and suppress findings. See also: model poisoning (glossary).

**5. Tool authorization abuse**
AI agents that invoke external tools (GitHub API, cloud APIs, CI/CD APIs) can be caused — through prompt injection or instruction override — to invoke those tools outside their intended scope. An agent authorized to read repositories may be manipulated into writing to them; an agent authorized to query vulnerability databases may be manipulated into opening or closing security issues.

### The AI Pipeline Attack Surface

The attack surface for AI components in a delivery pipeline spans:

```
External Attack Surface:
├── Open-source dependency names (slopsquatting targets)
├── Public CVE descriptions (indirect prompt injection source)
├── Public container image metadata / labels
└── Third-party SBOM component metadata

Internal Attack Surface:
├── Git commit messages and PR descriptions
├── Code comments in reviewed files
├── Issue and PR titles/bodies
├── GitHub Actions workflow annotations
├── CI/CD log output processed by AI components
└── SBOM and vulnerability report content passed to AI triage
```

Each of these surfaces represents a location where an adversary who can write content can potentially influence AI behavior without having direct code execution in the pipeline.

### Architectural Boundaries That Contain AI Risk

The core defensive principle is that **AI components should inform, not decide**. Every consequential pipeline action — merging code, approving a deployment, suppressing a security finding — must either require human confirmation or be validated by a deterministic control that cannot be manipulated through AI input channels.

```
Permitted: AI rates a PR as "low risk" and adds a label → human merges
Risky: AI rates a PR as "low risk" and merges it automatically

Permitted: AI triage suggests a CVE as "not exploitable" → human closes the finding
Risky: AI closes CVE findings that meet its "not exploitable" threshold without human review

Permitted: AI generates an IaC configuration → Checkov validates it before application
Risky: AI generates IaC → applied directly to infrastructure without deterministic validation
```

### Applying STRIDE to AI Pipeline Components

| Threat | AI-Specific Manifestation | Example |
|---|---|---|
| **Spoofing** | Adversarial content impersonates trusted context | Commit message crafted to look like internal security approval |
| **Tampering** | Prompt injection modifies AI's functional interpretation of inputs | Code comment overrides AI reviewer's analysis criteria |
| **Repudiation** | AI actions lack attribution to a reviewable decision chain | AI approves a merge; no audit trail links approval to specific prompt context |
| **Information Disclosure** | AI component leaks confidential context through outputs | AI summarizes a private security finding in a public-facing comment |
| **Denial of Service** | AI component is fed inputs that cause it to fail, time out, or produce no output | Adversarial inputs cause AI reviewer to refuse analysis, blocking the pipeline |
| **Elevation of Privilege** | AI agent invokes tools outside its intended authorization | Prompt injection causes read-only triage agent to close findings |

## Summary

AI components introduce a qualitatively different attack surface than traditional pipeline tools. They are susceptible to input manipulation, context distortion, and authorization abuse in ways that static analysis tools and scripts are not. The defensive posture must be architectural — limit AI to advisory roles, validate AI outputs with deterministic controls, maintain immutable audit trails of AI actions and the inputs that produced them, and apply least-privilege tool authorization to every AI agent.

**Next:** Chapter 2 examines prompt injection in depth — the specific attack patterns used against pipeline AI components and the practical defenses available to engineering teams.

## Lab

See [lab/README.md](lab/README.md) for a hands-on exercise mapping the attack surface of a sample AI-assisted pipeline and applying the STRIDE threat model to its AI components.
