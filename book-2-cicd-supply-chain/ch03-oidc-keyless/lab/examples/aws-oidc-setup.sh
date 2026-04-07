#!/usr/bin/env bash
# AWS OIDC Federation Setup for GitHub Actions
# Creates the OIDC identity provider and an IAM role with scoped permissions.
#
# Usage: ./aws-oidc-setup.sh <aws-account-id> <github-org> <github-repo>
# Example: ./aws-oidc-setup.sh 123456789012 my-org my-repo
#
# Prerequisites: AWS CLI configured with IAM permissions:
#   iam:CreateOpenIDConnectProvider, iam:CreateRole, iam:AttachRolePolicy
#
# This script is for educational purposes. In production, manage IAM resources
# with Terraform or CloudFormation for auditability and repeatability.

set -euo pipefail

ACCOUNT_ID="${1:?Usage: $0 <aws-account-id> <github-org> <github-repo>}"
GITHUB_ORG="${2:?Usage: $0 <aws-account-id> <github-org> <github-repo>}"
GITHUB_REPO="${3:?Usage: $0 <aws-account-id> <github-org> <github-repo>}"

OIDC_PROVIDER_URL="https://token.actions.githubusercontent.com"
ROLE_NAME="github-actions-${GITHUB_REPO}-deploy"

echo "=== Step 1: Create OIDC Identity Provider ==="
echo "Checking if OIDC provider already exists..."

EXISTING=$(aws iam list-open-id-connect-providers \
  --query "OpenIDConnectProviderList[?contains(Arn, 'token.actions.githubusercontent.com')].Arn" \
  --output text 2>/dev/null || true)

if [ -z "$EXISTING" ]; then
  echo "Creating OIDC provider for token.actions.githubusercontent.com..."
  PROVIDER_ARN=$(aws iam create-open-id-connect-provider \
    --url "${OIDC_PROVIDER_URL}" \
    --client-id-list "sts.amazonaws.com" \
    --thumbprint-list "6938fd4d98bab03faadb97b34396831e3780aea1" \
    --query OIDConnectProviderArn \
    --output text)
  echo "Created: ${PROVIDER_ARN}"
else
  PROVIDER_ARN="${EXISTING}"
  echo "Already exists: ${PROVIDER_ARN}"
fi

echo ""
echo "=== Step 2: Create Trust Policy ==="
TRUST_POLICY=$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "GitHubActionsOIDC",
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:${GITHUB_ORG}/${GITHUB_REPO}:ref:refs/heads/main"
        }
      }
    }
  ]
}
EOF
)

echo ""
echo "=== Step 3: Create IAM Role ==="
echo "Creating role: ${ROLE_NAME}"

ROLE_ARN=$(aws iam create-role \
  --role-name "${ROLE_NAME}" \
  --assume-role-policy-document "${TRUST_POLICY}" \
  --description "GitHub Actions OIDC role for ${GITHUB_ORG}/${GITHUB_REPO}" \
  --query Role.Arn \
  --output text)

echo "Role ARN: ${ROLE_ARN}"

echo ""
echo "=== Step 4: Attach Minimum Required Permissions ==="
# This attaches a minimal example policy — replace with your actual deployment permissions.
# In production, write a custom least-privilege policy instead of using managed policies.
aws iam attach-role-policy \
  --role-name "${ROLE_NAME}" \
  --policy-arn "arn:aws:iam::aws:policy/ReadOnlyAccess"

echo "Attached ReadOnlyAccess (replace with deployment-specific policy in production)"

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Add this to your GitHub Actions workflow:"
echo ""
echo "permissions:"
echo "  id-token: write   # Required for OIDC token request"
echo "  contents: read"
echo ""
echo "steps:"
echo "  - name: Configure AWS credentials"
echo "    uses: aws-actions/configure-aws-credentials@v4"
echo "    with:"
echo "      role-to-assume: ${ROLE_ARN}"
echo "      aws-region: us-east-1"
echo ""
echo "To test the configuration, verify the role can be assumed:"
echo "aws sts assume-role-with-web-identity \\"
echo "  --role-arn ${ROLE_ARN} \\"
echo "  --role-session-name test-session \\"
echo "  --web-identity-token <github-oidc-token>"
