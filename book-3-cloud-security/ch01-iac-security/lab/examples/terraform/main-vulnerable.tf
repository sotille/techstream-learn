# main-vulnerable.tf
# Intentionally misconfigured Terraform for Checkov lab exercises.
# DO NOT deploy to production. For learning purposes only.
#
# This file contains 6 deliberate misconfigurations:
# 1. S3 bucket with no Block Public Access settings
# 2. S3 bucket with no server-side encryption
# 3. S3 bucket with no versioning
# 4. Security group with unrestricted SSH (0.0.0.0/0) ingress
# 5. RDS instance with encryption disabled, publicly accessible, hardcoded password
# 6. IAM role with AdministratorAccess policy attached

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

# ---------------------------------------------------------------
# Issue 1, 2, 3: S3 bucket — no public access block, no encryption,
# no versioning. Checkov checks: CKV_AWS_18, CKV_AWS_19, CKV_AWS_21,
# CKV2_AWS_6, CKV2_AWS_62
# ---------------------------------------------------------------
resource "aws_s3_bucket" "data_lake" {
  bucket = "my-company-data-lake"

  tags = {
    Environment = "production"
    DataClass   = "sensitive"
  }
}

# ---------------------------------------------------------------
# Issue 4: Security group — SSH open to the entire internet.
# Checkov check: CKV_AWS_25
# ---------------------------------------------------------------
resource "aws_security_group" "bastion" {
  name        = "bastion-sg"
  description = "Security group for bastion host"
  vpc_id      = "vpc-12345678"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # ISSUE: open to the entire internet
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ---------------------------------------------------------------
# Issue 5: RDS instance — unencrypted, no multi-AZ, publicly
# accessible, hardcoded credential.
# Checkov checks: CKV_AWS_16, CKV_AWS_17, CKV_AWS_157, CKV_SECRET_6
# ---------------------------------------------------------------
resource "aws_db_instance" "app_database" {
  identifier        = "app-db-prod"
  engine            = "postgres"
  engine_version    = "15.4"
  instance_class    = "db.t3.medium"
  allocated_storage = 100
  username          = "dbadmin"
  password          = "SuperSecretPassword123!" # ISSUE: hardcoded credential

  storage_encrypted   = false # ISSUE: unencrypted storage at rest
  multi_az            = false # ISSUE: single-AZ — no HA
  publicly_accessible = true  # ISSUE: reachable from the public internet

  skip_final_snapshot = true
}

# ---------------------------------------------------------------
# Issue 6: IAM role with AdministratorAccess.
# Checkov check: CKV_AWS_274 (managed policy attachment check)
# ---------------------------------------------------------------
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
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess" # ISSUE: full admin access
}
