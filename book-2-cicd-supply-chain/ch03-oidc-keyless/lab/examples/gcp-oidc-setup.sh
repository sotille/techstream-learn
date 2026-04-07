#!/usr/bin/env bash
# GCP Workload Identity Federation Setup for GitHub Actions
# Track C companion to lab/README.md — "Configuring OIDC Federation for GitHub Actions"
#
# Prerequisites:
#   - gcloud CLI installed and authenticated
#   - A GCP project with billing enabled
#   - Project Owner or IAM Admin + Service Account Admin roles
#   - APIs enabled: iam.googleapis.com, iamcredentials.googleapis.com,
#     sts.googleapis.com, cloudresourcemanager.googleapis.com
#
# Usage: GCP_PROJECT_ID=your-project GITHUB_ORG=your-org GITHUB_REPO=your-repo ./gcp-oidc-setup.sh
#
# This script is for LEARNING purposes. It is intentionally verbose to show
# each step. In production, use Terraform to manage these resources.

set -euo pipefail

GCP_PROJECT_ID="${GCP_PROJECT_ID:?Set GCP_PROJECT_ID to your GCP project ID}"
GITHUB_ORG="${GITHUB_ORG:?Set GITHUB_ORG to your GitHub organization or username}"
GITHUB_REPO="${GITHUB_REPO:?Set GITHUB_REPO to your GitHub repository name}"

# --- Configuration --- #
POOL_NAME="github-actions-pool"
PROVIDER_NAME="github-provider"
SA_BUILD_NAME="github-build-sa"
SA_DEPLOY_NAME="github-deploy-sa"
LOCATION="global"

echo "==> Project:      ${GCP_PROJECT_ID}"
echo "==> Pool name:    ${POOL_NAME}"
echo "==> Provider:     ${PROVIDER_NAME}"
echo ""

# Set the default project
gcloud config set project "${GCP_PROJECT_ID}"

# --- Step 1: Enable required APIs --- #
echo "==> Step 1: Enabling required APIs..."
gcloud services enable \
  iam.googleapis.com \
  iamcredentials.googleapis.com \
  sts.googleapis.com \
  cloudresourcemanager.googleapis.com \
  --quiet

echo "    APIs enabled."

# --- Step 2: Create the Workload Identity Pool --- #
echo ""
echo "==> Step 2: Creating Workload Identity Pool..."

gcloud iam workload-identity-pools create "${POOL_NAME}" \
  --location="${LOCATION}" \
  --display-name="GitHub Actions Pool" \
  --description="Pool for GitHub Actions OIDC federation" \
  --quiet 2>/dev/null || echo "    (Pool already exists — continuing)"

POOL_RESOURCE="projects/${GCP_PROJECT_ID}/locations/${LOCATION}/workloadIdentityPools/${POOL_NAME}"
echo "    Pool resource: ${POOL_RESOURCE}"

# --- Step 3: Create the OIDC Provider --- #
echo ""
echo "==> Step 3: Creating GitHub OIDC provider in the pool..."

gcloud iam workload-identity-pools providers create-oidc "${PROVIDER_NAME}" \
  --location="${LOCATION}" \
  --workload-identity-pool="${POOL_NAME}" \
  --issuer-uri="https://token.actions.githubusercontent.com" \
  --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository,attribute.ref=assertion.ref" \
  --attribute-condition="attribute.repository=='${GITHUB_ORG}/${GITHUB_REPO}'" \
  --display-name="GitHub Actions OIDC" \
  --quiet 2>/dev/null || echo "    (Provider already exists — continuing)"

echo "    OIDC provider created with attribute condition restricting to ${GITHUB_ORG}/${GITHUB_REPO}"

# --- Step 4: Create Service Accounts --- #
echo ""
echo "==> Step 4: Creating service accounts..."

# Build service account — read-only, any branch
gcloud iam service-accounts create "${SA_BUILD_NAME}" \
  --display-name="GitHub Build SA (${GITHUB_REPO})" \
  --description="Used by GitHub Actions build jobs via OIDC — read access only" \
  --quiet 2>/dev/null || echo "    (Build SA already exists)"

BUILD_SA_EMAIL="${SA_BUILD_NAME}@${GCP_PROJECT_ID}.iam.gserviceaccount.com"
echo "    Build SA: ${BUILD_SA_EMAIL}"

# Deploy service account — elevated, main branch only
gcloud iam service-accounts create "${SA_DEPLOY_NAME}" \
  --display-name="GitHub Deploy SA (${GITHUB_REPO})" \
  --description="Used by GitHub Actions deploy jobs via OIDC — restricted to main branch" \
  --quiet 2>/dev/null || echo "    (Deploy SA already exists)"

DEPLOY_SA_EMAIL="${SA_DEPLOY_NAME}@${GCP_PROJECT_ID}.iam.gserviceaccount.com"
echo "    Deploy SA: ${DEPLOY_SA_EMAIL}"

# --- Step 5: Bind Workload Identity to Service Accounts --- #
echo ""
echo "==> Step 5: Binding Workload Identity pool to service accounts..."

PROJECT_NUMBER=$(gcloud projects describe "${GCP_PROJECT_ID}" --format="value(projectNumber)")

# Build SA: allow impersonation from any push to the repository
gcloud iam service-accounts add-iam-policy-binding "${BUILD_SA_EMAIL}" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL_NAME}/attribute.repository/${GITHUB_ORG}/${GITHUB_REPO}" \
  --quiet

echo "    Build SA binding: any push to ${GITHUB_ORG}/${GITHUB_REPO}"

# Deploy SA: allow impersonation only from main branch ref
gcloud iam service-accounts add-iam-policy-binding "${DEPLOY_SA_EMAIL}" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principal://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL_NAME}/subject/repo:${GITHUB_ORG}/${GITHUB_REPO}:ref:refs/heads/main" \
  --quiet

echo "    Deploy SA binding: main branch only"

# --- Step 6: Grant a minimal role to the build SA (demo) --- #
echo ""
echo "==> Step 6: Granting Viewer role to build SA (narrow scope in practice)..."

gcloud projects add-iam-policy-binding "${GCP_PROJECT_ID}" \
  --member="serviceAccount:${BUILD_SA_EMAIL}" \
  --role="roles/viewer" \
  --quiet

# --- Step 7: Output GitHub Actions workflow variables --- #
WORKLOAD_IDENTITY_PROVIDER="projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL_NAME}/providers/${PROVIDER_NAME}"

echo ""
echo "==> Step 7: GitHub Actions configuration"
echo "    Add the following secrets/variables to your GitHub repository:"
echo ""
echo "    GCP_WORKLOAD_IDENTITY_PROVIDER: ${WORKLOAD_IDENTITY_PROVIDER}"
echo "    GCP_BUILD_SERVICE_ACCOUNT:      ${BUILD_SA_EMAIL}"
echo ""

# --- Step 8: Example workflow --- #
cat <<'WORKFLOW'
==> Example GitHub Actions workflow step (add to .github/workflows/oidc-test.yml):

permissions:
  contents: read
  id-token: write       # Required to request the OIDC JWT

jobs:
  test-oidc-gcp:
    runs-on: ubuntu-latest
    steps:
      - name: Authenticate to GCP via Workload Identity Federation
        uses: google-github-actions/auth@71f986a2a41f966ac3f7baa0d1e8b89e5b64ede3  # v2.1.8
        with:
          workload_identity_provider: ${{ secrets.GCP_WORKLOAD_IDENTITY_PROVIDER }}
          service_account: ${{ secrets.GCP_BUILD_SERVICE_ACCOUNT }}

      - name: Set up gcloud
        uses: google-github-actions/setup-gcloud@77e7a554d41e2ee56fc945c52dfd3f33d12def9a  # v2.1.4

      - name: Verify authentication
        run: |
          gcloud auth list
          gcloud projects describe $GCP_PROJECT_ID
          echo "Successfully authenticated to GCP via OIDC — no service account key required"

WORKFLOW

echo ""
echo "==> Setup complete."
echo "    Push a commit to main and check the workflow runs successfully."
echo "    To verify in GCP: IAM > Service accounts > ${BUILD_SA_EMAIL} > Key activity"
echo ""
echo "==> Cleanup (when done with the lab):"
echo "    gcloud iam service-accounts delete ${BUILD_SA_EMAIL} --quiet"
echo "    gcloud iam service-accounts delete ${DEPLOY_SA_EMAIL} --quiet"
echo "    gcloud iam workload-identity-pools delete ${POOL_NAME} --location=global --quiet"
