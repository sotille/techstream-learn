# Chapter 3 — Supply Chain Attacks Targeting AI Components

## What You Will Learn

This chapter covers supply chain attacks specifically targeting the AI components used in software delivery pipelines. You will learn the attack patterns unique to AI supply chains — slopsquatting, model poisoning, fine-tuning data contamination, and compromised AI SDK dependencies — and understand how existing software supply chain controls must be extended to cover the AI components your organization consumes.

## Why This Matters

The software supply chain security discipline developed over the past decade — SBOMs, SLSA provenance, OIDC keyless signing — was designed for traditional software artifacts. When organizations deploy AI models, the same security properties (integrity, provenance, reproducibility) are required, but the existing tooling does not cover them automatically.

A compromised open-source model served from Hugging Face, a fine-tuned model trained on attacker-contributed data, or a package hallucinated by an AI coding assistant and registered by an attacker represents a supply chain compromise with the same blast radius as a compromised npm package — but with detection mechanisms that are far less mature.

## Key Concepts

### Slopsquatting

AI coding assistants (GitHub Copilot, Cursor, ChatGPT, Claude) frequently generate `import` statements or `pip install` / `npm install` commands referencing packages that do not exist in the target registry. The packages are plausible — they sound like real tools in the relevant ecosystem — but are hallucinations.

An attacker who monitors common AI code generation patterns can register these hallucinated package names in public registries and serve malicious code to any project that installs the AI-suggested package. This attack requires no compromise of the developer's toolchain, no social engineering, and no exploitation of any CVE — only the registration of a plausible package name.

**Observed risk factors:**
- Higher hallucination rates in less-common ecosystems (Ruby, Lua, Elixir) than in Python/npm
- Hallucination rates increase for niche domains (e.g., specialized cryptographic bindings, obscure cloud provider SDKs)
- Hallucination rates increase as models are pushed to generate complete boilerplate quickly

**Defenses against slopsquatting:**

1. **Package allowlist enforcement** — Maintain an allowlist of approved packages; any new package dependency triggers human review before installation. Implement with a private registry (Artifactory, Nexus, GitHub Packages) that mirrors only approved packages.

2. **SCA on all new dependencies** — Run SCA (Grype, Snyk, Dependabot) on every new package addition with a check for zero-download-count packages (a fresh registration with no organic usage history is a red flag).

3. **Human review policy for AI-suggested dependencies** — Require explicit human review and approval before adding any dependency suggested by an AI coding tool. Document this policy; enforce it in PR review guidelines.

4. **Lock files and reproducible installs** — `requirements.txt` with pinned versions, `package-lock.json`, `Cargo.lock`. A slopsquatted package can only be installed if the dependency is in the lock file; pinned installs prevent silent resolution to newly registered malicious packages.

### Model Poisoning and Training Data Contamination

Organizations fine-tuning models on proprietary codebases face a variant of dependency confusion: if the fine-tuning dataset includes code from public repositories that an attacker has contributed to, the attacker can influence the fine-tuned model's behavior.

**Attack scenario:** An adversary contributes carefully crafted code to a popular open-source project. The code is syntactically correct and passes review. When an organization fine-tunes a code review model on a corpus that includes this project, the fine-tuned model learns to treat the adversary's patterns as "normal" — and may subsequently rate security-relevant variants of those patterns as safe.

This is not a theoretical attack. The mechanism is the same as the XZ Utils backdoor, but targeting AI training data rather than build artifacts.

**Defenses against training data contamination:**

1. **Dataset integrity controls** — Apply SBOM-equivalent controls to fine-tuning datasets: document the sources, apply the same vetting standards as a software dependency (provenance, review status, organizational trustworthiness).

2. **Dataset signing** — Sign fine-tuning datasets before use; verify signatures in the training pipeline. Treat an unsigned dataset as an unverified dependency.

3. **Model behavioral testing** — After fine-tuning, run behavioral test suites that verify the model correctly identifies known-bad patterns. A model poisoned to ignore certain vulnerability classes will fail these tests.

4. **Rollback capability** — Maintain the ability to roll back to a prior model version if behavioral regression is detected post-deployment — the same capability as artifact rollback for traditional software.

### Model Provenance and Integrity

Public model repositories (Hugging Face, Ollama model library) serve hundreds of thousands of model files. Unlike npm or PyPI, these registries have less mature integrity controls:

- Model files are large (gigabytes); most users do not verify checksums
- Model cards (provenance documentation) are user-authored and unverified
- Some model file formats (pickle-based PyTorch `.pt` files) can execute arbitrary code when loaded

**Defenses for model file integrity:**

1. **SHA-256 checksum verification** — Pin the exact model file hash in your deployment configuration and verify before loading:
   ```bash
   # Verify before loading
   sha256sum -c model.sha256
   ```

2. **Prefer safe serialization formats** — Use `safetensors` format instead of pickle-based formats. `safetensors` is a header-only format that cannot execute code during deserialization.

3. **Cosign for model artifacts** — Some model registries support Cosign signing for model files. Where available, require signature verification before model loading in production.

4. **Model SBOM** — Generate a structured inventory of the model's training data provenance (to the extent known), architecture, base model lineage, and fine-tuning datasets. Treat this as the model equivalent of a software SBOM.

### AI SDK and Tooling Supply Chain

AI pipeline components depend on AI SDKs (LangChain, LlamaIndex, Anthropic SDK, OpenAI SDK) that are software dependencies governed by the same supply chain risks as any other open-source package. In 2024, several LangChain components had documented vulnerabilities enabling prompt injection and unsafe code execution.

Apply standard SCA practices to AI SDK dependencies:
- Pin versions; do not use `>=` requirements for AI SDK dependencies
- Subscribe to security advisories for AI SDKs used in production
- Treat AI SDK updates as high-priority security patches when they address prompt injection or code execution vulnerabilities
- Scan AI SDK dependencies with Grype or Snyk as part of CI; treat AI SDK CVEs with the same severity as equivalent CVEs in web frameworks

### Cross-Cutting: SLSA for AI Artifacts

The SLSA framework (Supply-chain Levels for Software Artifacts) applies to AI models as it applies to any artifact:

| SLSA Level | Traditional Software | AI Model Equivalent |
|---|---|---|
| **Level 1** | Build provenance documented | Model training run documented with dataset sources, base model, training parameters |
| **Level 2** | Build provenance signed by builder | Training provenance signed; model file checksums published |
| **Level 3** | Build environment hardened; provenance verified at deployment | Isolated training environment; training pipeline integrity controls; model signature verified before load |

Most organizations deploying third-party models are operating below SLSA Level 1 — no documented provenance for the models they use. Establishing Level 1 (documented provenance) is the immediate priority.

## Summary

AI supply chain attacks extend the existing software supply chain attack surface with novel vectors: slopsquatting (hallucinated packages registered by attackers), model poisoning (training data contamination), and model integrity failures (unsafe serialization formats, unverified model checksums). The defenses are extensions of existing practices — package allowlists, SCA, signature verification, behavioral testing — applied to the AI-specific artifacts your pipeline consumes.

The software supply chain security discipline exists precisely because the software ecosystem learned these lessons the hard way with SolarWinds, Codecov, and XZ Utils. The AI ecosystem is earlier in that maturity curve. Engineering teams that apply supply chain controls to their AI components now will be ahead of the attack curve when those incidents occur at scale.

**Next:** Chapter 4 covers agent forensics — investigating what happened when an AI component in your pipeline was compromised or behaved unexpectedly.

## Lab

See [lab/README.md](lab/README.md) for a hands-on exercise auditing AI dependencies for supply chain risks and implementing model checksum verification.
