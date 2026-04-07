# Lab 4 — Scanning and Hardening a Serverless Function Deployment

**Estimated time:** 45–60 minutes
**Difficulty:** Intermediate
**Prerequisites:**
- Python 3.8+ installed
- `pip install checkov grype` (or install grype via `brew install anchore/grype/grype`)
- Git and a text editor
- No AWS account required — all scanning is static analysis

---

## Setup

```bash
# Install required tools
pip install checkov

# Install Grype (binary release)
# macOS/Linux:
curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /usr/local/bin

# Verify installations
checkov --version
grype version
```

---

## Part 1: Scanning a Misconfigured Lambda Terraform Module

### Step 1 — Create the lab files

```bash
mkdir serverless-security-lab && cd serverless-security-lab
```

Create `lambda.tf` with intentional misconfigurations:

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

# Misconfiguration 1: Lambda function with credentials in environment variables
# Checkov: CKV_AWS_45
resource "aws_lambda_function" "data_processor" {
  filename         = "data_processor.zip"
  function_name    = "data-processor-prod"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "handler.process"
  runtime          = "python3.11"

  environment {
    variables = {
      DB_HOST     = "prod-db.internal"
      DB_PASSWORD = "SuperSecret123!"   # ISSUE: hardcoded credential
      API_KEY     = "sk-live-abcdef123" # ISSUE: hardcoded API key
    }
  }
}

# Misconfiguration 2: Lambda not attached to a VPC
# Checkov: CKV_AWS_117
# (No vpc_config block — function has unrestricted internet access)

# Misconfiguration 3: Lambda publicly accessible via resource-based policy
# Checkov: CKV_AWS_58
resource "aws_lambda_permission" "public_invoke" {
  statement_id  = "AllowPublicInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.data_processor.function_name
  principal     = "*"    # ISSUE: allows any AWS principal to invoke this function
}

# Misconfiguration 4: IAM role with over-broad permissions
# Checkov: CKV_AWS_274 (AdministratorAccess)
resource "aws_iam_role" "lambda_exec" {
  name = "lambda-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "admin" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"  # ISSUE: full admin access
}
```

### Step 2 — Run Checkov against the Lambda configuration

```bash
checkov -d . --framework terraform --compact
```

**Expected findings:**
- `CKV_AWS_45` — Lambda function has credentials in environment variables
- `CKV_AWS_117` — Lambda function is not inside a VPC
- `CKV_AWS_58` — Lambda function has a public resource-based policy
- `CKV_AWS_274` — Managed policy with admin access is attached to role

**Exercise:** Before running Checkov, list all the security issues you can spot manually.
Compare your list with Checkov's output. Note any issues Checkov found that you missed,
and any Checkov missed that you found.

### Step 3 — Remediate the misconfigurations

Apply the following fixes to `lambda.tf`:

**Fix 1 — Move secrets to Secrets Manager:**
```hcl
# Remove environment variables with secrets.
# Fetch secrets at runtime in the function code using boto3:
#   import boto3, json
#   secret = boto3.client('secretsmanager').get_secret_value(SecretId='prod/data-processor/config')
#   config = json.loads(secret['SecretString'])

environment {
  variables = {
    DB_HOST             = "prod-db.internal"       # Non-sensitive config OK
    SECRETS_MANAGER_ID  = "prod/data-processor/config"  # Tell function where to find secrets
  }
}
```

**Fix 2 — Attach the function to a VPC:**
```hcl
# Add vpc_config inside aws_lambda_function
vpc_config {
  subnet_ids         = ["subnet-abc12345", "subnet-def67890"]  # private subnets only
  security_group_ids = [aws_security_group.lambda_sg.id]
}
```

**Fix 3 — Restrict the resource-based policy:**
```hcl
# Replace principal = "*" with the specific service or account that should invoke this function
resource "aws_lambda_permission" "api_gateway_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.data_processor.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*"
}
```

**Fix 4 — Apply least-privilege IAM:**
```hcl
# Replace AdministratorAccess with a specific inline policy
resource "aws_iam_role_policy" "lambda_least_privilege" {
  name = "data-processor-policy"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = "arn:aws:s3:::my-input-bucket/input-data/*"
      },
      {
        Effect   = "Allow"
        Action   = ["dynamodb:PutItem"]
        Resource = "arn:aws:dynamodb:us-east-1:123456789:table/ProcessedRecords"
      },
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = "arn:aws:secretsmanager:us-east-1:123456789:secret:prod/data-processor/config-*"
      },
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:us-east-1:*:*"
      }
    ]
  })
}
```

After applying all fixes, re-run Checkov and confirm all findings are resolved.

---

## Part 2: SCA for Lambda Deployment Packages

Lambda functions bundle their dependencies in a ZIP file. These dependencies may contain
known vulnerabilities that standard image scanning misses. Grype can scan Lambda ZIP packages.

### Step 4 — Create a deliberately vulnerable Python dependency set

```bash
mkdir lambda-package && cd lambda-package

# Create a requirements.txt with a known-vulnerable package version
# requests 2.20.0 contains SSRF and cookie leak vulnerabilities (CVE-2023-32681 and older)
cat > requirements.txt << 'EOF'
requests==2.20.0
boto3==1.26.0
EOF

# Install dependencies into a package directory (simulates Lambda ZIP creation)
pip install -r requirements.txt -t ./package/ --quiet

# Create a simple handler
cat > handler.py << 'EOF'
import json
import requests

def process(event, context):
    # Simplified handler for lab purposes
    url = event.get("url", "https://example.com")
    response = requests.get(url, timeout=5)
    return {"statusCode": 200, "body": response.text[:200]}
EOF

# Create the deployment ZIP
zip -r ../lambda-function.zip . -x "*.pyc" "__pycache__/*" > /dev/null
cd ..
```

### Step 5 — Scan the Lambda ZIP with Grype

```bash
grype ./lambda-function.zip
```

**Expected output:** Grype will identify vulnerabilities in `requests 2.20.0`, including
CVE-2023-32681 (cookie leakage via redirect) and other findings.

**Key observation:** This is the same package that passes `pip install` with no warning.
Only SCA scanning reveals the known vulnerabilities.

### Step 6 — Remediate by updating dependencies

```bash
# Update requirements.txt to current versions
cat > lambda-package/requirements.txt << 'EOF'
requests>=2.32.0
boto3>=1.34.0
EOF

# Rebuild the package
pip install -r lambda-package/requirements.txt -t ./lambda-package/package/ --quiet --upgrade
zip -r lambda-function-fixed.zip lambda-package/ -x "*.pyc" "__pycache__/*" > /dev/null

# Re-scan
grype ./lambda-function-fixed.zip
```

Confirm that the CVEs from `requests 2.20.0` are no longer reported.

---

## Part 3: CI/CD Integration

The same Checkov and Grype scans from Parts 1 and 2 should run in your CI pipeline
before any Lambda deployment. See `examples/github-actions/serverless-security.yml` for
a reference GitHub Actions workflow that performs both scans automatically on every pull
request.

---

## Reflection Questions

1. Lambda functions have a maximum execution timeout (15 minutes for AWS). How does this
   limit affect an attacker who has achieved code execution via event injection — compared
   to a persistent process in a container?

2. You discover that a Lambda function processing S3 events has `s3:*` on `*` in its
   execution role. Outline a remediation approach that does not require downtime and
   explains how you would determine the minimum required permissions.

3. A developer argues that attaching a Lambda to a VPC introduces cold-start latency and
   that the function doesn't process sensitive data. What are the security arguments for
   VPC attachment that apply regardless of data sensitivity?

4. Your Grype scan identifies 12 vulnerabilities in Lambda dependencies. 3 are Critical,
   7 are High, 2 are Medium. The function is deployed daily. Describe a triage approach
   for the team's first sprint of remediation.
