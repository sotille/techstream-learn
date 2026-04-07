# Minimal distroless base image — no shell, no package manager, minimal attack surface.
# Used in the artifact integrity lab as the signing target.
# cgr.dev/chainguard/static is equivalent to gcr.io/distroless/static but with
# regular automated rebuilds and SBOM attestations pre-attached.
FROM cgr.dev/chainguard/static:latest

LABEL org.opencontainers.image.source="https://github.com/${GITHUB_REPOSITORY}"
LABEL org.opencontainers.image.description="Techstream artifact integrity lab — test image"
LABEL org.opencontainers.image.licenses="Apache-2.0"
