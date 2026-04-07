# Chapter 2 — SLSA and SBOM: Establishing Software Supply Chain Trust

## What You Will Learn

How do you prove that a software artifact you are deploying is the same one that was built from the source code you reviewed? How do you know what open source components are embedded in a container image you are running in production — and whether any of them have known vulnerabilities? SLSA and SBOM are the two foundational standards for answering these questions.

By the end of this chapter, you will understand:

- The four levels of the SLSA framework and what each level guarantees
- How SLSA provenance attestations are generated and verified
- The SBOM formats (CycloneDX and SPDX) and when to use each
- Which tools generate high-quality SBOMs and how to integrate them into a pipeline
- How to verify SBOM attestations at deployment time using Kyverno policies
- How SLSA and SBOM together create an end-to-end verifiable supply chain

## Why It Matters

Without provenance attestations, you cannot verify that the container image you are deploying was built from the commit you approved. Without an SBOM, you cannot determine which of your running applications is affected when a critical CVE is disclosed in a popular library. Both problems are not hypothetical — the SolarWinds attackers exploited the absence of build provenance verification to inject malicious code into signed artifacts for months without detection.

SLSA and SBOM are now regulatory requirements in some sectors. US Executive Order 14028 requires SBOMs for software sold to the federal government. The EU Cyber Resilience Act mandates SBOM disclosure for products sold in the European market. Getting ahead of these requirements through good tooling practice is significantly less costly than retrofitting them under audit pressure.

## Key Concepts

**SLSA (Supply Chain Levels for Software Artifacts)**: A graduated security framework defining four levels of supply chain integrity, from basic build hygiene (Level 1: existence of provenance) to hermetic, reproducible builds with strong, verifiable attestations (Level 4).

| SLSA Level | Key Requirements | What It Prevents |
|---|---|---|
| Level 1 | Provenance exists (unsigned) | Accidental source confusion |
| Level 2 | Hosted build service; signed provenance | Tampering by individual developers |
| Level 3 | Hardened build platform; non-falsifiable provenance | Compromise of individual build steps |
| Level 4 | Hermetic builds; two-party review; reproducibility | Compromise of the build platform itself |

**Build provenance**: A cryptographically verifiable statement describing how, when, and where an artifact was built — including the source repository, commit hash, build system, inputs, and configuration. The SLSA specification defines the provenance schema; Sigstore's Rekor transparency log provides the verification infrastructure.

**SBOM (Software Bill of Materials)**: A machine-readable inventory of all software components, libraries, and dependencies in an artifact. The two dominant formats are:
- **CycloneDX** (OWASP): security-focused; native VEX support; best for vulnerability correlation and pipeline policy enforcement
- **SPDX** (Linux Foundation/ISO): license-focused; ISO/IEC 5962 standardized; best for legal review and open source transparency

**Cosign and Sigstore**: The open source infrastructure for signing and verifying software artifacts. Cosign attaches SLSA provenance and SBOM attestations to container images as OCI artifacts alongside the image in the registry. Fulcio provides keyless certificate issuance; Rekor provides a tamper-evident transparency log.

## SBOM Tool Landscape

Three tools dominate pipeline SBOM generation:

| Tool | Strengths | Best For |
|---|---|---|
| **Syft** (Anchore) | Broad language support; Cosign integration; fast | General-purpose container and filesystem SBOM |
| **Trivy** (Aqua) | Combined SBOM + vulnerability scanning; Kubernetes support | Teams wanting one tool for both |
| **cdxgen** (OWASP) | Deepest CycloneDX support; polyglot repos; build environment capture | Java/Maven, Node.js, complex monorepos |

## Framework Reference

This chapter is based on the Software Supply Chain Security Framework:

- [SBOM Format and Tool Selection Guide](../../software-supply-chain-security-framework/docs/sbom-guide.md)
- [SLSA Level Advancement Guide](../../software-supply-chain-security-framework/docs/slsa-level-advancement.md)
- [Framework Overview](../../software-supply-chain-security-framework/docs/framework.md)

## Lab

See [lab/README.md](lab/README.md) for the hands-on exercise: **Generating and Attesting an SBOM with CycloneDX and Cosign**.
