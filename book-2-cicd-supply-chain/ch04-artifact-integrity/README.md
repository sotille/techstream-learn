# Chapter 4 — Artifact Integrity: Signing, Verification, and Promotion Gates

**Volume:** Book 2 — Securing CI/CD & the Software Supply Chain
**Framework reference:** [secure-ci-cd-reference-architecture](../../../../secure-ci-cd-reference-architecture/docs/framework.md) | [software-supply-chain-security-framework](../../../../software-supply-chain-security-framework/docs/slsa-level-advancement.md)

---

## What You Will Learn

This chapter addresses a gap that appears in nearly every CI/CD implementation: security scanning tells you whether code is safe *before* it is packaged, but nothing prevents the resulting artifact from being modified or replaced *after* it passes those scans. Artifact signing closes this gap by providing cryptographic proof of:

1. **Who built the artifact** — the identity of the CI/CD pipeline (not a human with stored keys)
2. **What source it was built from** — the exact commit SHA and repository
3. **That it has not changed since it was signed** — any post-signing modification breaks the signature

By the end of this chapter you will be able to implement a complete artifact integrity chain using Cosign, configure signature verification as a deployment gate, and understand how SLSA provenance extends signing with build traceability.

---

## Why Artifact Integrity Matters

Consider what happens between the SAST scan and the production deployment in a typical pipeline:

```
Source → Build → SAST (pass) → SCA (pass) → Container Scan (pass) → Push to Registry → Deploy Staging → Deploy Production
```

The security scans run against the artifact at build time. But the artifact persists in a registry — sometimes for hours, sometimes for months. Between the scan and the deployment, several tampering scenarios are possible:

- A malicious insider with registry write access replaces the image tag
- A misconfigured registry allows unauthenticated writes
- A pipeline misconfiguration rebuilds the artifact for each environment (the production artifact is different from the one that was scanned)
- A typosquatting attack substitutes an image at a dependency pull step

Signing the artifact immediately after scanning, and verifying the signature immediately before deployment, closes all of these vectors. Only artifacts with valid signatures can proceed to production.

---

## Cosign and Keyless Signing

[Cosign](https://docs.sigstore.dev/cosign/overview/) is the CNCF standard for container image and artifact signing. It supports two signing models:

### Key-Based Signing (Legacy)

The pipeline uses a long-lived private key stored in a secret manager. The public key is distributed to verification points. This model works but has operational costs: key rotation, key access controls, and key storage policies all require ongoing management.

### Keyless Signing (Recommended)

Keyless signing uses OIDC federation to tie the signature to the identity of the CI/CD pipeline job itself — no stored key required. The signing process:

1. The pipeline job requests an OIDC token from the CI platform (GitHub Actions, GitLab CI)
2. The OIDC token is presented to Fulcio (the Sigstore certificate authority)
3. Fulcio issues a short-lived signing certificate bound to the OIDC identity (e.g., `https://github.com/org/repo/.github/workflows/build.yml@refs/heads/main`)
4. Cosign uses the ephemeral key to sign the artifact and records the signature in Rekor (the public transparency log)
5. The certificate and private key are discarded after signing

Verification later confirms: this artifact was signed by the specific pipeline workflow, from the specific repository, on the specific branch. The transparency log makes the signing event tamper-evident.

---

## SLSA Provenance and Build Traceability

Signing proves that an artifact is authentic. SLSA provenance proves *how* it was built.

A SLSA provenance attestation is a signed document that records:
- The builder identity (the CI platform and workflow)
- The source repository and exact commit digest
- The inputs to the build (dependencies used)
- The build start time and configuration

At SLSA Level 2, provenance is signed by the build service. At SLSA Level 3, the build runs in an isolated environment and the provenance cannot be forged even by the repository owner.

The `slsa-github-generator` project provides reusable GitHub Actions workflows that generate SLSA Level 3 provenance automatically. Lab 4 in this chapter demonstrates this.

---

## Promotion Gates

A promotion gate is a policy check that must pass before an artifact can move from one environment to the next. Artifact signing enables policy-based promotion gates:

```
Build → Sign → Push to registry
                      ↓
                Deploy to staging (verify signature)
                      ↓
                Deploy to production (verify signature + SLSA provenance)
```

Policy enforcement tools such as Kyverno (Kubernetes), OPA, and Cosign's policy engine (`cosign verify --certificate-identity`) can be configured to reject any image that:
- Has no Cosign signature
- Has a signature from an unexpected signer identity
- Has a signature that does not match the expected workflow
- Lacks a SLSA provenance attestation (for production)

This prevents "tag mutation" attacks and enforces that only pipeline-built artifacts reach production.

---

## Key Concepts in This Chapter

| Concept | What It Means |
|---------|--------------|
| Artifact signing | Cryptographic signature over the artifact digest, tied to the signer identity |
| Keyless signing | Signing using ephemeral OIDC-derived keys — no long-lived secret required |
| Rekor | Sigstore's transparency log — a tamper-evident record of every signing event |
| Fulcio | Sigstore's certificate authority — issues signing certificates bound to OIDC identity |
| SLSA provenance | Signed attestation of build inputs, builder identity, and build configuration |
| Promotion gate | Policy check requiring a valid signature before allowing deployment progression |
| Digest reference | Addressing a container image by its sha256 digest rather than a mutable tag |

---

## Lab Exercise

The hands-on lab for this chapter walks through:
1. Signing a container image with Cosign keyless signing in GitHub Actions
2. Verifying the signature locally and in a deployment workflow
3. Generating SLSA provenance with the `slsa-github-generator`
4. Implementing a signature verification gate in a Kubernetes deployment workflow

See [lab/README.md](lab/README.md) to begin.

---

## Further Reading

- Cosign documentation: `docs.sigstore.dev`
- [secure-ci-cd-reference-architecture: Artifact Signing](../../../../secure-ci-cd-reference-architecture/docs/framework.md) — production framework implementation
- [SLSA Level Advancement Guide](../../../../software-supply-chain-security-framework/docs/slsa-level-advancement.md) — advancing from SLSA L1 to L3
- [sbom-guide.md](../../../../software-supply-chain-security-framework/docs/sbom-guide.md) — SBOM generation pairs with signing for complete supply chain integrity
