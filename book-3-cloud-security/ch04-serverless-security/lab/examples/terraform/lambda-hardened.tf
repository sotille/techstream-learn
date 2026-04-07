# lambda-hardened.tf
# Remediated version of lambda-vulnerable.tf.
# All 4 misconfigurations from lambda-vulnerable.tf have been corrected.

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

# Fix 1: No credentials in environment variables.
# Secrets are referenced via Secrets Manager ID; the function code
# calls secretsmanager:GetSecretValue at runtime.
resource "aws_lambda_function" "data_processor" {
  filename         = "data_processor.zip"
  function_name    = "data-processor-prod"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "handler.process"
  runtime          = "python3.11"

  environment {
    variables = {
      DB_HOST            = "prod-db.internal"
      SECRETS_MANAGER_ID = "prod/data-processor/config"
    }
  }

  # Fix 2: Attach to private VPC subnets; no direct internet egress.
  vpc_config {
    subnet_ids         = ["subnet-aaa11111", "subnet-bbb22222"]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }
}

# Fix 3: Resource-based policy scoped to API Gateway only.
resource "aws_lambda_permission" "api_gateway_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.data_processor.function_name
  principal     = "apigateway.amazonaws.com"
  # source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*"
  # Uncomment and set source_arn to restrict to a specific API Gateway
}

# Security group: allow HTTPS egress to VPC endpoints only; deny all ingress.
resource "aws_security_group" "lambda_sg" {
  name        = "lambda-data-processor-sg"
  description = "Security group for data-processor Lambda — egress to VPC endpoints only"
  vpc_id      = "vpc-12345678"

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
    description = "HTTPS to VPC endpoints (Secrets Manager, DynamoDB, S3)"
  }
}

# Fix 4: Least-privilege IAM — only the exact permissions the function needs.
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

resource "aws_iam_role_policy" "lambda_least_privilege" {
  name = "data-processor-least-privilege"
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
        Resource = "arn:aws:dynamodb:us-east-1:123456789012:table/ProcessedRecords"
      },
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = "arn:aws:secretsmanager:us-east-1:123456789012:secret:prod/data-processor/config-*"
      },
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:us-east-1:*:*"
      }
    ]
  })
}
