# Lab 1 — Scanning IaC for Cloud Misconfigurations with Checkov

**Estimated time:** 45–60 minutes
**Difficulty:** Beginner–Intermediate
**Prerequisites:**
- Python 3.8+ installed (for Checkov installation via pip)
- Git and a text editor
- A GitHub account (for Part 3: CI/CD integration)
- No cloud provider access required — all scanning is static analysis against code

---

## Setup: Install Checkov

```bash
# Install Checkov (requires Python 3.8+)
pip install checkov

# Verify installation
checkov --version
```

---

## Part 1: Scanning a Terraform Module with Intentional Misconfigurations

### Step 1 — Create the Lab Terraform Files

Create a directory for this lab and add the following files. These are intentionally misconfigured — the lab exercises identify and fix each issue.

```bash
mkdir checkov-lab && cd checkov-lab
```

Create `main.tf`:

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Misconfiguration 1: Public S3 bucket (no Block Public Access)
resource "aws_s3_bucket" "data_lake" {
  bucket = "my-company-data-lake"

  tags = {
    Environment = "production"
    DataClass   = "sensitive"
  }
}

# Misconfiguration 2: No server-side encryption
# (Missing aws_s3_bucket_server_side_encryption_configuration)

# Misconfiguration 3: No bucket versioning
# (Missing aws_s3_bucket_versioning)

# Misconfiguration 4: Security group with unrestricted SSH ingress
resource "aws_security_group" "bastion" {
  name        = "bastion-sg"
  description = "Security group for bastion host"
  vpc_id      = "vpc-12345678"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]   # ISSUE: open to the entire internet
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Misconfiguration 5: RDS without encryption and multi-AZ disabled
resource "aws_db_instance" "app_database" {
  identifier        = "app-db-prod"
  engine            = "postgres"
  engine_version    = "15.4"
  instance_class    = "db.t3.medium"
  allocated_storage = 100
  username          = "dbadmin"
  password          = "SuperSecretPassword123!"   # ISSUE: hardcoded credential

  storage_encrypted = false    # ISSUE: unencrypted storage
  multi_az          = false    # ISSUE: no high availability
  publicly_accessible = true   # ISSUE: public internet access

  skip_final_snapshot = true
}

# Misconfiguration 6: IAM role with admin access
resource "aws_iam_role" "app_role" {
  name = "app-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "admin_attachment" {
  role       = aws_iam_role.app_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"  # ISSUE: admin access
}
```

### Step 2 — Run Checkov Against the Configuration

```bash
# Run Checkov against the current directory
checkov -d . --framework terraform

# Expected: multiple FAILED checks across the resources above
```

**Exercise:** Before reading the output, list the misconfigurations you can see in the Terraform above. Then compare your list with Checkov's findings. Are there any Checkov found that you missed? Any you found that Checkov missed?

### Step 3 — Interpret Checkov Output

Checkov output follows this format for each failing check:

```
Check: CKV_AWS_20: "Ensure the S3 bucket has access control list (ACL) applied"
FAILED for resource: aws_s3_bucket.data_lake
File: /main.tf:10-19
Guide: https://docs.bridgecrew.io/docs/s3_1-acl-prohibited
```

For each failing check, identify:
- The rule ID (`CKV_AWS_20`) — used for suppression if needed
- The severity (shown with `--check-severity` flag)
- The resource and line number
- The remediation guide link

### Step 4 — Fix the Misconfigurations

Fix each issue in `main.tf`. For reference, the correct configurations:

**S3 Block Public Access:**
```hcl
resource "aws_s3_bucket_public_access_block" "data_lake" {
  bucket                  = aws_s3_bucket.data_lake.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

**S3 Server-Side Encryption:**
```hcl
resource "aws_s3_bucket_server_side_encryption_configuration" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}
```

**Security Group (restrict to known CIDR):**
```hcl
ingress {
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["10.0.0.0/8"]   # Internal network only
}
```

**RDS (enable encryption, disable public access):**
```hcl
storage_encrypted   = true
multi_az            = true
publicly_accessible = false
# Remove hardcoded password — use aws_secretsmanager_secret_version or var
```

**IAM (remove admin policy):**
```hcl
# Replace AdministratorAccess with a least-privilege custom policy
# e.g., only the specific actions the application requires
```

After each fix, re-run Checkov to verify the check passes.

---

## Part 2: Running a Compliance-Scoped Scan

Checkov can produce a compliance-focused report. This is useful for audit preparation.

```bash
# Run CIS AWS Foundations Benchmark scan only
checkov -d . --framework terraform --check CKV_AWS_1,CKV_AWS_2 --compact

# Run all checks mapped to HIPAA
checkov -d . --framework terraform --compliance hipaa

# Run all checks mapped to SOC 2
checkov -d . --framework terraform --compliance soc2

# Generate a JUnit XML report for CI integration
checkov -d . --framework terraform --output junitxml > checkov-results.xml
```

---

## Part 3: CI/CD Pipeline Integration

Integrate Checkov into a GitHub Actions pipeline to block IaC deployments with critical misconfigurations.

Create `.github/workflows/iac-security.yml`:

```yaml
name: IaC Security Scan

on:
  pull_request:
    paths:
      - '**.tf'
      - '**.yml'
      - '**.yaml'

jobs:
  checkov:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      security-events: write    # For SARIF upload to GitHub Security tab

    steps:
      - name: Checkout
        uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683

      - name: Run Checkov IaC scan
        id: checkov
        uses: bridgecrewio/checkov-action@v12
        with:
          directory: .
          framework: terraform
          output_format: sarif
          output_file_path: checkov-results.sarif
          soft_fail: false    # Block PR on CRITICAL/HIGH findings
          check: CKV_AWS_*   # Scope to AWS checks; adjust per your environment

      - name: Upload SARIF results to GitHub Security tab
        if: always()
        uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: checkov-results.sarif
```

Push this to a PR that includes the misconfigured `main.tf`. Observe that the PR check fails and the SARIF results appear in the GitHub Security tab under "Code scanning."

---

## Part 4: Writing a Custom Checkov Policy

Organization-specific controls can be defined as custom policies. This example enforces a tagging standard.

Create `custom_checks/check_required_tags.py`:

```python
from checkov.common.models.enums import CheckResult, CheckCategories
from checkov.terraform.checks.resource.base_resource_check import BaseResourceCheck


class CheckRequiredTags(BaseResourceCheck):
    """
    All resources must have Environment and DataClass tags.
    """

    REQUIRED_TAGS = {"Environment", "DataClass"}

    def __init__(self):
        name = "Ensure all resources have required Techstream tags"
        id = "CKV_CUSTOM_1"
        supported_resources = [
            "aws_s3_bucket",
            "aws_db_instance",
            "aws_instance",
            "aws_eks_cluster",
        ]
        categories = [CheckCategories.GENERAL_SECURITY]
        super().__init__(name=name, id=id, categories=categories,
                         supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        tags = conf.get("tags")
        if not tags:
            return CheckResult.FAILED

        # Handle Terraform's nested list format
        if isinstance(tags, list):
            tags = tags[0] if tags else {}

        missing = self.REQUIRED_TAGS - set(tags.keys())
        if missing:
            return CheckResult.FAILED

        return CheckResult.PASSED


scanner = CheckRequiredTags()
```

Run with the custom check:

```bash
checkov -d . --external-checks-dir custom_checks --check CKV_CUSTOM_1
```

---

## Reflection Questions

1. Checkov identifies `storage_encrypted = false` as a failing check. Is this a vulnerability or a misconfiguration? What is the distinction, and why does it matter for remediation prioritization?

2. The lab Terraform includes a hardcoded database password. Checkov detects this via secrets scanning rules (`CKV_SECRET_*`). What is the correct alternative in Terraform for managing database credentials at apply time?

3. Running Checkov in `soft_fail = false` mode will block PRs that touch any `.tf` file if any check fails. For a team migrating a large existing codebase, this could block all infrastructure changes on day one. How would you phase the rollout of hard enforcement without abandoning security controls?

4. Checkov scans the Terraform source. It cannot scan the actual deployed state of your cloud environment. Name two scenarios where a resource that passes Checkov in the code base is misconfigured in production.
