# Chapter 1 — Why AI Changes the DevSecOps Threat Model

## What You Will Learn

This chapter explains how AI integration into the software delivery lifecycle introduces qualitatively new attack surfaces that traditional DevSecOps controls were not designed to address. You will learn to identify the five layers where AI enters the delivery pipeline, characterize the unique threats at each layer, and understand the foundational concept that drives the rest of this book: the difference between AI-specific threats and AI-amplified traditional threats.

## Why This Matters

Organizations are adopting AI-assisted development tools — IDE code completion, AI-powered code review, LLM-based vulnerability triage — faster than they are understanding the security implications. The result is a gap between the trust these components receive within pipelines and the rigor of the security controls applied to them.

The gap has consequences. In early 2024, researchers demonstrated that AI coding assistants could generate package names that do not exist in public registries but could be registered by an adversary — the **slopsquatting** attack surface. AI code reviewers have been shown to approve pull requests containing backdoors when adversarial instructions are embedded in code comments. AI-assisted triage tools can be caused to suppress real findings by crafting CVE descriptions that contain instruction-like language.

These are not theoretical risks. They are documented attack patterns against real AI integrations deployed in production today.

## The Five AI Integration Layers

AI enters the software delivery lifecycle at five layers, each with a distinct trust model and attack surface:

**Layer 1 — Developer environment:** IDE plugins, code completion assistants (GitHub Copilot, Cursor, Cody), local LLMs. Threats: data exfiltration via AI assistant context, slopsquatting in generated code, developer over-trust in AI suggestions.

**Layer 2 — AI-powered code review:** PR analysis agents, inline AI suggestions, automated review bots. Threats: adversarial code designed to fool AI reviewers, PR description prompt injection, AI review output used as an authority signal without human verification.

**Layer 3 — CI/CD AI integration:** Test generation, pipeline intelligence, AI-assisted security scanning. Threats: context window poisoning with large CI inputs, indirect prompt injection via commit messages or SBOM metadata, tool authorization abuse by agents operating in the pipeline.

**Layer 4 — Deployment automation with AI:** Rollout decision support, configuration generation, AI-assisted change management. Threats: AI-generated IaC misconfigurations, prompt injection in deployment inputs, AI approval of changes it should have blocked.

**Layer 5 — Production AI operations:** Autonomous remediation agents, AIOps, AI-driven incident response. Threats: agent blast radius when compromised, cascade compromise in multi-agent systems, unauthorized actions by agents in production environments.

## Model Supply Chain Threats

AI integration into the software delivery lifecycle introduces a new supply chain attack surface: the model itself. Unlike traditional software supply chain attacks that target code or packages, model supply chain attacks target the ML model weights, fine-tuning pipelines, and model distribution infrastructure.

**Threat 1 — Pickle deserialization attacks:** PyTorch model files (`.pt`, `.pth`) use Python pickle serialization by default. Pickle can instantiate arbitrary Python objects during deserialization, which means a malicious model file can execute arbitrary code when loaded. An attacker who can substitute a model file in the distribution path — via a compromised model registry, a man-in-the-middle on an unverified HTTPS download, or a compromised artifact storage bucket — can achieve code execution in the CI/CD environment that loads the model.

**Threat 2 — Fine-tuning data poisoning:** Organizations that fine-tune foundation models on internal data introduce a training data supply chain. If the fine-tuning dataset is assembled from sources that an attacker can influence (internal code repositories, ticket systems, documentation), adversarial examples can be injected. The result is a model with subtly altered behavior for specific inputs — for example, a code completion model that generates insecure patterns for specific functions, or a security classification model that systematically misclassifies a specific attacker-controlled threat category.

**Threat 3 — Version substitution:** Model registries without digest-based integrity verification can have model versions silently replaced. Unlike software packages where version pinning provides some protection, model versioning systems often rely on mutable tags (e.g., `model:v2.1`) that can be overwritten. An attacker with write access to the model registry can substitute a compromised model under the same version tag.

**Control requirements (see [model-supply-chain.md](../../ai-devsecops-framework/docs/model-supply-chain.md)):**
- Digest-based integrity verification before any model is loaded (SHA-256 or stronger)
- ModelScan or equivalent deserialization safety scanning for all pickle-format models
- Cosign-based model signing with signature verification at load time
- Immutable model registry with separate signing key hierarchy from code signing

This threat category feeds directly into Chapter 7 (model supply chain integrity lab) and illustrates why AI-specific supply chain controls are distinct from software supply chain controls.

---

## AI-Specific Threats vs. AI-Amplified Traditional Threats

Not all risks introduced by AI are new. Some are amplifications of existing threat categories:

**AI-amplified traditional threats:** Dependency confusion (now exploitable via slopsquatting at AI-hallucination scale), typosquatting (now executable by generating plausible package names algorithmically), phishing (now scalable via LLM-generated social engineering).

**AI-specific threats:** Prompt injection (no analog in traditional software), model supply chain attacks (different from software supply chain attacks in mechanisms), non-determinism as a security property (the same input to an AI component may produce different outputs with different security consequences), emergent behaviors in multi-agent systems.

Understanding which category a threat belongs to determines where to apply controls. AI-amplified threats often respond to existing controls applied more rigorously. AI-specific threats require new control categories.

## Mapping AI Threats to STRIDE

AI-specific threats do not replace traditional threat modeling frameworks — they extend them. STRIDE (Spoofing, Tampering, Repudiation, Information Disclosure, Denial of Service, Elevation of Privilege) maps to AI threats as follows, providing a structured vocabulary for AI threat modeling used throughout this book and formalized in Chapter 8:

| STRIDE Category | AI-Specific Instantiations |
|---|---|
| **Spoofing** | Prompt injection impersonating a trusted user or system role; jailbreak instructions claiming special authority ("you are now in developer mode") |
| **Tampering** | Training data poisoning; model weight substitution; adversarial examples that alter classification output; context window manipulation that changes downstream reasoning |
| **Repudiation** | Agent taking actions without auditable authorization records; non-determinism exploited to claim a specific tool call could not have been intentional |
| **Information Disclosure** | Prompt extraction via adversarial queries; context leakage between multi-tenant sessions; AI assistant exfiltrating code context to external providers |
| **Denial of Service** | Context window exhaustion via large malicious inputs; runaway agent loops consuming API quota; model collapse under adversarial load |
| **Elevation of Privilege** | Jailbreak overriding model safety constraints; cascade compromise propagating through multi-agent authority chain; tool authorization policy bypass via injection |

The maturity model from Chapter 18 anchors threat coverage to organizational capability: organizations at Level 1 (AI-Naive) typically have no controls for any STRIDE category applied to AI components; Level 3 (AI-Defended) organizations have controls for Spoofing, Tampering, and Elevation of Privilege; Level 5 organizations have systematic controls and continuous adversarial testing across all categories.

---

## What You Will Practice

This chapter's lab focuses on slopsquatting detection — one of the most immediately actionable AI-specific threats in the developer environment layer. You will:

- Review a list of AI-generated dependency names and identify which exhibit slopsquatting characteristics
- Configure a SCA tool check that detects packages present in code but absent from a private registry mirror
- Trace how slopsquatting progresses from AI suggestion to supply chain compromise if left undetected

## Lab

See [lab/README.md](lab/README.md) for the hands-on exercise on detecting slopsquatting with SCA tooling.
