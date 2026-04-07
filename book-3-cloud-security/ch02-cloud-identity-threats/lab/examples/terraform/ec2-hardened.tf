# EDUCATIONAL EXAMPLE — Hardened IMDSv2 Configuration
# This Terraform configuration enforces IMDSv2:
# - http_tokens = "required": all metadata requests must include a session token
# - http_put_response_hop_limit = 1: prevents container workloads inside the instance
#   from accessing the instance's metadata endpoint (containers are one hop away)
#
# Checkov rule CKV_AWS_79 will PASS against this configuration.

resource "aws_instance" "app_server" {
  ami           = "ami-0c02fb55956c7d316"
  instance_type = "t3.micro"

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"  # IMDSv2: session token required for all requests
    http_put_response_hop_limit = 1           # Limit metadata access to the instance itself
  }

  iam_instance_profile = "web-app-role"

  root_block_device {
    encrypted = true  # CKV_AWS_8: encrypt root volume at rest
  }

  tags = {
    Name = "app-server"
    env  = "prod"
    team = "web"
  }
}
