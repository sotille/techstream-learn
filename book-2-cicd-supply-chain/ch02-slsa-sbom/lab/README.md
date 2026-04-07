# Lab 2 — Generating and Attesting an SBOM with CycloneDX and Cosign

**Estimated time:** 45–55 minutes
**Difficulty:** Intermediate
**Prerequisites:**
- Docker installed locally
- `syft` installed (`curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin`)
- `cosign` installed (`brew install cosign` or download from https://github.com/sigstore/cosign/releases)
- A container image to analyze (you can use `nginx:1.25-alpine` or any public image)

---

## Objective

Generate a CycloneDX SBOM for a container image, validate it against NTIA minimum elements, and attach it to the image as a Cosign attestation. By the end of this lab, you will understand the full SBOM generation and attestation workflow that belongs in every production CI/CD pipeline.

---

## Step 1 — Generate a CycloneDX SBOM with Syft

Pull the example image and generate a CycloneDX SBOM:

```bash
# Pull the image
docker pull nginx:1.25-alpine

# Generate a CycloneDX SBOM from the pulled image
syft nginx:1.25-alpine -o cyclonedx-json=nginx-sbom.cdx.json

# Inspect the output
cat nginx-sbom.cdx.json | jq '.metadata.component.name, .metadata.timestamp'
cat nginx-sbom.cdx.json | jq '.components | length'
```

**Questions:**
1. How many components were found?
2. What is the `metadata.component.type` of the top-level component?
3. Are there components from multiple package ecosystems (apk, npm, python)?

---

## Step 2 — Validate NTIA Minimum Elements

The US NTIA defines minimum elements that every SBOM must contain. Validate your SBOM:

```bash
# Check that PURLs are present for all components
cat nginx-sbom.cdx.json | jq '[.components[] | select(.purl == null or .purl == "")] | length'
# Expected: 0 (all components should have PURLs)

# Check that versions are present
cat nginx-sbom.cdx.json | jq '[.components[] | select(.version == null or .version == "")] | length'
# Expected: 0 or very low (a few unknown versions is acceptable for OS packages)

# Check for dependency relationships
cat nginx-sbom.cdx.json | jq '.dependencies | length'
# Expected: > 0 (relationship graph populated)

# Check metadata fields (NTIA: author, timestamp)
cat nginx-sbom.cdx.json | jq '.metadata | {timestamp, authors, tools}'
```

**Questions:**
1. Does the SBOM pass all NTIA minimum element checks?
2. Are there components with missing PURLs? What type are they?
3. Is the dependency relationship graph populated?

---

## Step 3 — Generate an SPDX SBOM and Compare

```bash
# Generate the same image as SPDX for comparison
syft nginx:1.25-alpine -o spdx-json=nginx-sbom.spdx.json

# Compare sizes
ls -la nginx-sbom.cdx.json nginx-sbom.spdx.json

# Compare component counts
cat nginx-sbom.spdx.json | jq '.packages | length'
cat nginx-sbom.cdx.json | jq '.components | length'

# Check license expression support (SPDX strength)
cat nginx-sbom.spdx.json | jq '.packages[:3] | .[].licenseConcluded'
```

**Questions:**
1. Which format produces a larger file? By what factor?
2. Are the component counts identical between formats?
3. How does the license expression coverage compare?

---

## Step 4 — Scan the SBOM for Vulnerabilities with Grype

```bash
# Install Grype if not present
curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /usr/local/bin

# Scan the SBOM (not the image directly — use the already-generated SBOM)
grype sbom:nginx-sbom.cdx.json

# Get structured output
grype sbom:nginx-sbom.cdx.json -o json | jq '.matches | group_by(.vulnerability.severity) | map({severity: .[0].vulnerability.severity, count: length})'
```

**Questions:**
1. How many vulnerabilities were found?
2. What is the breakdown by severity?
3. Are there any Critical or High severity vulnerabilities?

---

## Step 5 — Attach the SBOM as a Cosign Attestation (Keyless)

In a real pipeline, this step runs after building the image and pushing it to a registry. For this lab, we simulate the attestation workflow using keyless signing against the Sigstore public infrastructure.

```bash
# Note: This step requires the image to be in a registry you control.
# If you don't have a registry, skip to Step 6 and read the pipeline example.

# Example (replace with your registry and image):
IMAGE="ttl.sh/learn-lab-$(date +%s):1h"  # ttl.sh is a free temporary registry

# Push the image
docker tag nginx:1.25-alpine $IMAGE
docker push $IMAGE

# Get the image digest (required for attestation — tag is mutable, digest is not)
DIGEST=$(docker inspect --format='{{index .RepoDigests 0}}' $IMAGE | cut -d@ -f2)
echo "Image digest: $DIGEST"

# Attach the SBOM as a CycloneDX attestation
cosign attest \
  --predicate nginx-sbom.cdx.json \
  --type cyclonedx \
  $IMAGE@$DIGEST
# This will open a browser for OIDC authentication via Sigstore Fulcio

# Verify the attestation
cosign verify-attestation \
  --type cyclonedx \
  --certificate-identity-regexp '.*' \
  --certificate-oidc-issuer https://accounts.google.com \
  $IMAGE@$DIGEST
```

---

## Step 6 — Review the GitHub Actions Integration

Review the example GitHub Actions workflow in `examples/sbom-pipeline.yml`. Identify:

1. At what stage in the pipeline is the SBOM generated? Why at this stage (not earlier or later)?
2. How is the image digest passed between pipeline steps to ensure SBOM and attestation reference the same artifact?
3. What would need to change to add SPDX output in addition to CycloneDX?
4. What Kyverno policy could enforce that all pods have a valid SBOM attestation before scheduling?

---

## Deliverable

A brief lab report (markdown file) containing:
1. Component count from Syft SBOM
2. NTIA validation results (pass/fail per field)
3. Vulnerability scan summary (count by severity)
4. Answer to the four questions in Step 6
5. One improvement you would make to the example pipeline
