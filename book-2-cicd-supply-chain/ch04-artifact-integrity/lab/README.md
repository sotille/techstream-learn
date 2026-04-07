# Lab 4 — Signing Container Images with Cosign and Verifying Signatures

**Estimated time:** 45–60 minutes
**Difficulty:** Intermediate
**Prerequisites:**
- A GitHub repository with GitHub Actions enabled
- Docker or Podman installed locally
- `cosign` CLI installed (see installation below)
- A container registry (GitHub Container Registry — ghcr.io — works free with your GitHub account)
- Chapter 3 OIDC lab completed (or understand how OIDC federation works)

---

## Setup: Install the Cosign CLI

```bash
# macOS (Homebrew)
brew install sigstore/tap/cosign

# Linux (download binary)
curl -O -L "https://github.com/sigstore/cosign/releases/latest/download/cosign-linux-amd64"
sudo mv cosign-linux-amd64 /usr/local/bin/cosign
sudo chmod +x /usr/local/bin/cosign

# Verify installation
cosign version
```

---

## Part 1: Keyless Signing in GitHub Actions

### Step 1 — Create the Pipeline Workflow

Create `.github/workflows/sign-and-verify.yml` in your test repository:

```yaml
name: Build, Sign, and Verify Container Image

on:
  push:
    branches: [main]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

permissions:
  contents: read
  packages: write
  id-token: write   # Required for OIDC token request (keyless signing)

jobs:
  build-sign-verify:
    runs-on: ubuntu-latest
    outputs:
      image-digest: ${{ steps.build.outputs.digest }}

    steps:
      - name: Checkout
        uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683  # v4.2.2

      # Step 1a: Authenticate to registry
      - name: Log in to container registry
        uses: docker/login-action@9780b0c442fbb1117ed29e0efdff1e18412f7567  # v3.3.0
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      # Step 1b: Extract metadata for tagging
      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@369eb591f429131d6889c46b94e711f089e6ca96  # v5.6.1
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=sha,format=long

      # Step 1c: Build and push the image — note the digest output
      - name: Build and push image
        id: build
        uses: docker/build-push-action@4f58ea79222b3b9dc2c8bbdd6debcef730109a75  # v6.9.0
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}

      # Step 1d: Sign the image digest (keyless — uses OIDC identity)
      - name: Sign the image with Cosign (keyless)
        env:
          DIGEST: ${{ steps.build.outputs.digest }}
          TAGS: ${{ steps.meta.outputs.tags }}
        run: |
          echo "==> Signing image digest: ${DIGEST}"
          echo "==> Signer OIDC identity: ${{ github.workflow }}@${{ github.ref }}"

          images=""
          for tag in ${TAGS}; do
            images="${images} ${tag}@${DIGEST}"
          done

          cosign sign --yes ${images}

          echo "Signature stored in registry alongside image"
          echo "Signing event recorded in Rekor transparency log"

      # Step 1e: Verify the signature (simulating a downstream deployment check)
      - name: Verify image signature
        env:
          DIGEST: ${{ steps.build.outputs.digest }}
        run: |
          echo "==> Verifying signature for ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}@${DIGEST}"

          cosign verify \
            --certificate-identity-regexp="https://github.com/${{ github.repository }}/.github/workflows/.*" \
            --certificate-oidc-issuer="https://token.actions.githubusercontent.com" \
            "${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}@${DIGEST}" | jq .

          echo "Signature verified — artifact authenticity confirmed"
```

### Step 2 — Add a Minimal Dockerfile

If your repository does not have a Dockerfile, create one for this lab:

```dockerfile
# Dockerfile — minimal test image for artifact signing lab
FROM cgr.dev/chainguard/static:latest
LABEL org.opencontainers.image.source="https://github.com/${GITHUB_REPOSITORY}"
LABEL org.opencontainers.image.description="Techstream artifact signing lab — test image"
```

### Step 3 — Push and Observe

Push a commit to `main`. Watch the workflow run. When it completes:

1. Navigate to your GitHub packages page and find the container image
2. In the `github.com/<org>/<repo>/pkgs/container/<repo>` page, look for the signature entry (it appears as a separate artifact alongside the image)

---

## Part 2: Verifying a Signature Locally

After the pipeline runs, verify the signature from your workstation:

```bash
# Set variables to match your repository
REGISTRY="ghcr.io"
IMAGE="ghcr.io/YOUR_ORG/YOUR_REPO"
DIGEST="sha256:..."   # Get this from the workflow output or package page

# Verify the signature
cosign verify \
  --certificate-identity-regexp="https://github.com/YOUR_ORG/YOUR_REPO/.github/workflows/.*" \
  --certificate-oidc-issuer="https://token.actions.githubusercontent.com" \
  "${IMAGE}@${DIGEST}" | jq '.[0] | {subject: .critical.identity.docker_reference, signer: .optional.Subject}'
```

Expected output format:
```json
{
  "subject": "ghcr.io/your-org/your-repo",
  "signer": "https://github.com/your-org/your-repo/.github/workflows/sign-and-verify.yml@refs/heads/main"
}
```

This confirms: the image was signed by the exact workflow file, from the exact repository, on the main branch.

---

## Part 3: Verify the Transparency Log Entry

Every keyless signing operation is recorded in the Rekor public transparency log. This log is tamper-evident: entries cannot be deleted or modified.

```bash
# Look up the Rekor entry for your signing event
REKOR_SEARCH_URL="https://rekor.sigstore.dev/api/v1/index/retrieve"

# Get the Rekor log entry UUID for your signing event
cosign triangulate "${IMAGE}@${DIGEST}"

# Fetch the entry from Rekor (replace UUID with actual value from triangulate output)
rekor-cli get --uuid YOUR_REKOR_UUID --format json | jq '{
  logIndex: .logIndex,
  body: (.body | @base64d | fromjson | .spec.signature.content),
  integratedTime: .integratedTime
}'
```

The Rekor entry proves: at a specific point in time, this specific pipeline signed this specific artifact. This record cannot be retroactively added or altered.

---

## Part 4: Generating SLSA Provenance

Cosign signing proves who signed the artifact and that it has not changed. SLSA provenance proves *how it was built*. The `slsa-github-generator` generates SLSA Level 3 provenance using a separate, isolated signing workflow.

Add this job to your workflow (it must be a separate job, not a step in the build job):

```yaml
# Add to the jobs section — after the build-sign-verify job
generate-provenance:
  needs: [build-sign-verify]
  permissions:
    actions: read
    id-token: write
    packages: write
  uses: slsa-framework/slsa-github-generator/.github/workflows/generator_container_slsa3.yml@v2.0.0
  with:
    image: ghcr.io/${{ github.repository }}
    digest: ${{ needs.build-sign-verify.outputs.image-digest }}
    registry-username: ${{ github.actor }}
  secrets:
    registry-password: ${{ secrets.GITHUB_TOKEN }}
```

After this runs, verify the SLSA provenance:

```bash
cosign verify-attestation \
  --certificate-identity-regexp="https://github.com/slsa-framework/slsa-github-generator/.*" \
  --certificate-oidc-issuer="https://token.actions.githubusercontent.com" \
  --type slsaprovenance \
  "${IMAGE}@${DIGEST}" | jq '.payload | @base64d | fromjson | .predicate'
```

The decoded predicate shows: builder ID, source repository digest, workflow entrypoint, and build timestamp.

---

## Verification Exercises

1. **Attempt to verify an unsigned image**: Run `cosign verify` against a public image that has no signature (e.g., an older Alpine image). Note the error message and what it means.

2. **Test signature scope enforcement**: After completing the lab, change the `--certificate-identity-regexp` to a wrong workflow path. The verification should fail with an identity mismatch. This simulates what happens if a different workflow or repository attempts to use a signature it did not create.

3. **Confirm digest immutability**: Push an updated image with the same tag. The old digest still has a valid signature. The new image (with the same tag, different digest) has no signature until re-signed. This demonstrates why production deployments should always use digest references, never tags.

4. **Inspect the Fulcio certificate**: Run `cosign verify ... --output-certificate` to see the X.509 certificate issued by Fulcio. Identify the Subject Alternative Name (SAN) — it encodes the exact OIDC identity that performed the signing.

---

## Reflection Questions

1. A security engineer argues that SAST scanning already ensures artifact integrity — "if it passed the scan, it's safe." What specific attack scenarios does signing prevent that SAST cannot?

2. Keyless signing uses ephemeral certificates with a 10-minute validity window. After the certificate expires, is the signature still valid? Why?

3. What is the difference between verifying with `--certificate-identity` (exact match) vs `--certificate-identity-regexp` (regex)? Which should you use in a deployment gate, and why?

4. SLSA Level 3 provenance is generated by a *separate* GitHub Actions workflow, not the workflow that ran the build. Why is this architectural separation required for Level 3 attestations?
