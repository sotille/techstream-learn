# lambda-vulnerable.tf
# Intentionally misconfigured Lambda Terraform for Checkov lab exercises (Part 1).
# DO NOT deploy to production. For learning purposes only.
#
# Misconfigurations:
# 1. CKV_AWS_45  — Credentials in environment variables
# 2. CKV_AWS_117 — Lambda not attached to a VPC
# 3. CKV_AWS_58  — Lambda publicly accessible via resource-based policy
# 4. CKV_AWS_274 — AdministratorAccess policy attached to execution role

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
  # ISSUE: No vpc_config block — function not in VPC
}

resource "aws_lambda_permission" "public_invoke" {
  statement_id  = "AllowPublicInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.data_processor.function_name
  principal     = "*" # ISSUE: any AWS principal can invoke
}

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
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess" # ISSUE: full admin
}
