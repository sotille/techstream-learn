#!/usr/bin/env bash
# verify-signature.sh — Local signature verification for a container image
#
# Usage:
#   ./verify-signature.sh <image-reference-with-digest>
#
# Example:
#   ./verify-signature.sh ghcr.io/your-org/your-repo@sha256:abc123...
#
# Prerequisites:
#   - cosign CLI installed (brew install sigstore/tap/cosign)
#   - jq installed (brew install jq)
#   - The image must have been signed by the sign-and-verify.yml workflow

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <image@digest>"
  echo "Example: $0 ghcr.io/your-org/your-repo@sha256:abc123..."
  exit 1
fi

IMAGE_REF="$1"

# Extract org/repo from the image reference for the identity regexp.
# Expected format: ghcr.io/ORG/REPO@sha256:...
REPO_PATH=$(echo "${IMAGE_REF}" | sed 's|ghcr.io/||' | cut -d'@' -f1)

echo "==> Verifying signature for: ${IMAGE_REF}"
echo "==> Expected signer repository: ${REPO_PATH}"
echo ""

# Verify the image signature. The certificate-identity-regexp must match the
# workflow file path that performed the signing.
cosign verify \
  --certificate-identity-regexp="https://github.com/${REPO_PATH}/.github/workflows/.*" \
  --certificate-oidc-issuer="https://token.actions.githubusercontent.com" \
  "${IMAGE_REF}" \
  | jq '.[0] | {
      subject: .critical.identity.docker_reference,
      signer: .optional.Subject,
      issuer: .optional.Issuer
    }'

echo ""
echo "==> Signature verified — artifact authenticity confirmed"
echo ""

# Look up the Rekor transparency log entry to confirm tamper-evident audit record.
echo "==> Retrieving Rekor transparency log reference..."
cosign triangulate "${IMAGE_REF}" && echo "(Use rekor-cli get --uuid <UUID> to inspect the full log entry)"
