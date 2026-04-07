#!/usr/bin/env bash
# Azure OIDC Federation Setup for GitHub Actions
# Track B companion to lab/README.md — "Configuring OIDC Federation for GitHub Actions"
#
# Prerequisites:
#   - Azure CLI installed and authenticated (az login)
#   - A GitHub repository (set GITHUB_ORG and GITHUB_REPO below)
#   - Contributor or Owner role on the subscription
#   - Microsoft.Web and Microsoft.ManagedIdentity resource providers registered
#
# Usage: GITHUB_ORG=your-org GITHUB_REPO=your-repo ./azure-oidc-setup.sh
#
# This script is for LEARNING purposes. It is intentionally verbose to show
# each step. In production, use Terraform or Bicep to manage these resources.

set -euo pipefail

GITHUB_ORG="${GITHUB_ORG:?Set GITHUB_ORG to your GitHub organization or username}"
GITHUB_REPO="${GITHUB_REPO:?Set GITHUB_REPO to your GitHub repository name}"

# --- Configuration --- #
APP_NAME="github-oidc-${GITHUB_REPO}"
SUBSCRIPTION_ID=$(az account show --query id --output tsv)
TENANT_ID=$(az account show --query tenantId --output tsv)

echo "==> Subscription: ${SUBSCRIPTION_ID}"
echo "==> Tenant:       ${TENANT_ID}"
echo "==> App name:     ${APP_NAME}"
echo ""

# --- Step 1: Create the App Registration --- #
echo "==> Step 1: Creating Azure AD app registration..."

APP_ID=$(az ad app create \
  --display-name "${APP_NAME}" \
  --query appId \
  --output tsv)

echo "    App ID: ${APP_ID}"

# Create a service principal for the app
SP_OBJECT_ID=$(az ad sp create \
  --id "${APP_ID}" \
  --query id \
  --output tsv)

echo "    Service Principal Object ID: ${SP_OBJECT_ID}"

# --- Step 2: Create Federated Identity Credentials --- #
echo ""
echo "==> Step 2: Creating federated identity credentials..."

# Credential for main branch builds (any branch trigger)
echo "    Creating build credential (main branch)..."
az ad app federated-credential create \
  --id "${APP_ID}" \
  --parameters "{
    \"name\": \"github-build-main\",
    \"issuer\": \"https://token.actions.githubusercontent.com\",
    \"subject\": \"repo:${GITHUB_ORG}/${GITHUB_REPO}:ref:refs/heads/main\",
    \"description\": \"GitHub Actions build jobs on main branch\",
    \"audiences\": [\"api://AzureADTokenExchange\"]
  }"

# Credential for staging environment deployments
echo "    Creating deploy credential (staging environment)..."
az ad app federated-credential create \
  --id "${APP_ID}" \
  --parameters "{
    \"name\": \"github-deploy-staging\",
    \"issuer\": \"https://token.actions.githubusercontent.com\",
    \"subject\": \"repo:${GITHUB_ORG}/${GITHUB_REPO}:environment:staging\",
    \"description\": \"GitHub Actions deploy jobs targeting the staging environment\",
    \"audiences\": [\"api://AzureADTokenExchange\"]
  }"

# --- Step 3: Assign a Minimal Role --- #
echo ""
echo "==> Step 3: Assigning Reader role at subscription scope (demo — narrow to resource group in practice)..."

az role assignment create \
  --assignee-object-id "${SP_OBJECT_ID}" \
  --assignee-principal-type ServicePrincipal \
  --role "Reader" \
  --scope "/subscriptions/${SUBSCRIPTION_ID}"

echo "    Role assigned."

# --- Step 4: Output GitHub Actions workflow variables --- #
echo ""
echo "==> Step 4: GitHub Actions configuration"
echo "    Add the following secrets/variables to your GitHub repository:"
echo ""
echo "    AZURE_CLIENT_ID:       ${APP_ID}"
echo "    AZURE_TENANT_ID:       ${TENANT_ID}"
echo "    AZURE_SUBSCRIPTION_ID: ${SUBSCRIPTION_ID}"
echo ""

# --- Step 5: Print example GitHub Actions workflow --- #
cat <<'WORKFLOW'
==> Example GitHub Actions workflow step (add to .github/workflows/oidc-test.yml):

permissions:
  contents: read
  id-token: write       # Required to request the OIDC JWT

jobs:
  test-oidc-azure:
    runs-on: ubuntu-latest
    steps:
      - name: Authenticate to Azure via OIDC
        uses: azure/login@a457da9ea143d694b1b9c7c869ebb04ebe844ef5  # v2.3.0
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

      - name: Verify authentication
        run: |
          az account show
          echo "Successfully authenticated to Azure via OIDC — no client secrets required"

WORKFLOW

# --- Step 6: Verification --- #
echo ""
echo "==> Step 6: Verify the federated credentials were created"
az ad app federated-credential list --id "${APP_ID}" --query "[].{name:name,subject:subject}" --output table

echo ""
echo "==> Setup complete."
echo "    Push a commit to main and check the workflow runs successfully."
echo "    To verify the sign-in in Azure AD: Portal > App registrations > ${APP_NAME} > Sign-in logs"
echo ""
echo "==> Cleanup (when done with the lab):"
echo "    az ad app delete --id ${APP_ID}"
echo "    az role assignment delete --assignee ${SP_OBJECT_ID} --role Reader --scope /subscriptions/${SUBSCRIPTION_ID}"
