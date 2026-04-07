# main-hardened.tf
# Remediated version of main-vulnerable.tf for Checkov lab exercises.
# All 6 misconfigurations from main-vulnerable.tf have been corrected.
# Compare with main-vulnerable.tf to understand each remediation.

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
# Fix 1, 2, 3: S3 bucket with public access block, encryption,
# and versioning enabled.
# ---------------------------------------------------------------
resource "aws_s3_bucket" "data_lake" {
  bucket = "my-company-data-lake"

  tags = {
    Environment = "production"
    DataClass   = "sensitive"
  }
}

resource "aws_s3_bucket_public_access_block" "data_lake" {
  bucket                  = aws_s3_bucket.data_lake.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_versioning" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id
  versioning_configuration {
    status = "Enabled"
  }
}

# ---------------------------------------------------------------
# Fix 4: Security group — SSH restricted to internal CIDR only.
# ---------------------------------------------------------------
resource "aws_security_group" "bastion" {
  name        = "bastion-sg"
  description = "Security group for bastion host — internal SSH only"
  vpc_id      = "vpc-12345678"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"] # FIX: internal network only
    description = "SSH from internal network only"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }
}

# ---------------------------------------------------------------
# Fix 5: RDS instance — encryption enabled, no public access,
# multi-AZ enabled, password from Secrets Manager (not hardcoded).
# ---------------------------------------------------------------

# Retrieve database password from AWS Secrets Manager at apply time.
# The secret must be pre-created: aws secretsmanager create-secret \
#   --name "prod/app-database/dbadmin" --secret-string '{"password":"<value>"}'
data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = "prod/app-database/dbadmin"
}

resource "aws_db_instance" "app_database" {
  identifier        = "app-db-prod"
  engine            = "postgres"
  engine_version    = "15.4"
  instance_class    = "db.t3.medium"
  allocated_storage = 100
  username          = "dbadmin"
  password          = jsondecode(data.aws_secretsmanager_secret_version.db_password.secret_string)["password"]

  storage_encrypted   = true  # FIX: encryption at rest enabled
  multi_az            = true  # FIX: multi-AZ for high availability
  publicly_accessible = false # FIX: no public internet access

  # Enable automated backups (required for read replica support and PITR)
  backup_retention_period = 7
  deletion_protection     = true

  skip_final_snapshot = false
  final_snapshot_identifier = "app-db-prod-final"
}

# ---------------------------------------------------------------
# Fix 6: IAM role with least-privilege custom policy instead of
# AdministratorAccess.
# Scope permissions to exactly what the application needs.
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

resource "aws_iam_role_policy" "app_least_privilege" {
  name = "app-service-least-privilege"
  role = aws_iam_role.app_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Example: read from one S3 bucket prefix only
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:ListBucket"]
        Resource = [
          aws_s3_bucket.data_lake.arn,
          "${aws_s3_bucket.data_lake.arn}/app-data/*"
        ]
      },
      {
        # Example: write to Secrets Manager for credential rotation check
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = "arn:aws:secretsmanager:us-east-1:*:secret:prod/app-*"
      }
    ]
  })
}
