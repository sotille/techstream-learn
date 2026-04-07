# Lab 3 — Configuring OIDC Federation for GitHub Actions

**Estimated time:** 50–60 minutes
**Difficulty:** Intermediate
**Prerequisites:**
- AWS, Azure, or GCP account with permission to create IAM roles/policies
- A GitHub repository (can be a test repo created for this lab)
- `aws` CLI, `az` CLI, or `gcloud` CLI installed and authenticated
- Basic familiarity with IAM concepts

This lab has three tracks — choose the cloud provider you are most familiar with:
- [Track A: GitHub Actions → AWS](#track-a-github-actions--aws)
- [Track B: GitHub Actions → Azure](#track-b-github-actions--azure)
- [Track C: GitHub Actions → GCP](#track-c-github-actions--gcp)

---

## Before You Start: Inventory Your Current Secrets

Before configuring OIDC, take stock of what long-lived credentials currently exist in your CI/CD configuration.

**Exercise:** List all CI/CD secrets in your test repository that contain cloud credentials (AWS access keys, service account keys, API tokens). For each, note:
- What cloud account/service it accesses
- What permissions it has
- When it was last rotated
- Whether it is used in any pipeline today

This inventory will become your OIDC migration target list.

---

## Track A: GitHub Actions → AWS

### Step 1 — Create the OIDC Identity Provider

```bash
# Create the GitHub Actions OIDC provider in AWS IAM
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1

# Verify creation
aws iam get-open-id-connect-provider \
  --open-id-connect-provider-arn $(aws iam list-open-id-connect-providers \
    --query "OpenIDConnectProviderList[?contains(Arn,'token.actions.githubusercontent.com')].Arn" \
    --output text)
```

### Step 2 — Create Separate IAM Roles for Build and Deploy

Replace `YOUR_GITHUB_ORG` and `YOUR_GITHUB_REPO` with your actual values.

```bash
GITHUB_ORG="YOUR_GITHUB_ORG"
GITHUB_REPO="YOUR_GITHUB_REPO"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
OIDC_ARN="arn:aws:iam::${ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"

# Build role trust policy — any branch in the repository
cat > build-trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "${OIDC_ARN}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:${GITHUB_ORG}/${GITHUB_REPO}:*"
        }
      }
    }
  ]
}
EOF

aws iam create-role \
  --role-name github-build-${GITHUB_REPO} \
  --assume-role-policy-document file://build-trust-policy.json

# Deploy role trust policy — main branch only, with environment restriction
cat > deploy-trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "${OIDC_ARN}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
          "token.actions.githubusercontent.com:sub": "repo:${GITHUB_ORG}/${GITHUB_REPO}:environment:staging"
        }
      }
    }
  ]
}
EOF

aws iam create-role \
  --role-name github-deploy-staging-${GITHUB_REPO} \
  --assume-role-policy-document file://deploy-trust-policy.json

# Attach a minimal permission policy to the build role (read-only example)
aws iam attach-role-policy \
  --role-name github-build-${GITHUB_REPO} \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly
```

### Step 3 — Create the GitHub Actions Workflow

Create `.github/workflows/oidc-test.yml` in your repository:

```yaml
name: OIDC Authentication Test

on:
  push:
    branches: [main]

permissions:
  contents: read
  id-token: write  # Required to request the OIDC JWT

jobs:
  test-oidc:
    runs-on: ubuntu-latest
    steps:
      - name: Configure AWS credentials via OIDC
        uses: aws-actions/configure-aws-credentials@e3dd6a429d7300a6a4c196c26e071d42e0343502
        with:
          role-to-assume: arn:aws:iam::YOUR_ACCOUNT_ID:role/github-build-YOUR_REPO
          aws-region: us-east-1
          role-session-name: github-oidc-test-${{ github.run_id }}
          role-duration-seconds: 900

      - name: Verify credentials work
        run: |
          aws sts get-caller-identity
          echo "Successfully authenticated via OIDC — no static credentials required"

      - name: Verify credential lifetime (should show ~15 min expiry)
        run: |
          aws sts get-caller-identity --query 'Arn' --output text
```

### Step 4 — Validate the Setup

After the workflow runs successfully:

```bash
# Verify the CloudTrail event was logged
aws logs filter-log-events \
  --log-group-name CloudTrail/AssumeRoleWithWebIdentity \
  --filter-pattern "github-build" \
  --start-time $(date -d '1 hour ago' +%s000) 2>/dev/null || \
  echo "Check CloudTrail console for AssumeRoleWithWebIdentity events"

# Review the role assumption in CloudTrail
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=AssumeRoleWithWebIdentity \
  --max-results 5
```

---

## Track B: GitHub Actions → Azure

See `examples/azure-oidc-setup.sh` for the Azure OIDC configuration commands equivalent to Track A.

---

## Track C: GitHub Actions → GCP

See `examples/gcp-oidc-setup.sh` for the GCP Workload Identity Federation configuration commands.

---

## Verification Exercise (All Tracks)

After completing your chosen track:

1. **Confirm no static credentials exist**: Remove any static cloud credentials from your repository secrets. The workflow should still succeed using OIDC.

2. **Test subject claim restriction**: Temporarily modify the trust policy to restrict to a specific branch that doesn't exist. Verify that the workflow fails with an `AccessDenied` error when run from `main`.

3. **Review the audit trail**: Find the `AssumeRoleWithWebIdentity` (AWS) or equivalent sign-in event in your cloud provider's audit logs. What claims are recorded?

4. **Test the separation**: Try calling a deploy-role action from the build job (it should fail because the build role lacks deploy permissions).

---

## Reflection Questions

1. What is the maximum credential lifetime used in this lab? Why is 15 minutes the recommended minimum?

2. If an attacker stole the OIDC JWT token from a running pipeline job, what could they do with it? What prevents them from reusing it later?

3. Why is the `environment:production` subject claim more restrictive than `ref:refs/heads/main`? What additional protection does it provide?

4. What would you need to change to allow this pipeline to run from a feature branch in a non-production environment?
