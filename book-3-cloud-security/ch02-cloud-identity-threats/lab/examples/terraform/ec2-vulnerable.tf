# EDUCATIONAL EXAMPLE — Intentionally Vulnerable Configuration
# This Terraform configuration allows IMDSv1 (no session token required).
# IMDSv1 is exploitable via SSRF: an attacker who can induce the application
# to make HTTP requests can query http://169.254.169.254 to retrieve IAM credentials.
#
# Checkov rule CKV_AWS_79 will FAIL against this configuration.
# See ec2-hardened.tf for the corrected version.

resource "aws_instance" "app_server" {
  ami           = "ami-0c02fb55956c7d316"
  instance_type = "t3.micro"

  # metadata_options block is absent.
  # AWS default: http_tokens = "optional" (IMDSv1 allowed)
  # This means unauthenticated metadata requests succeed — exploitable via SSRF.

  iam_instance_profile = "web-app-role"

  tags = {
    Name = "app-server"
    env  = "prod"
    team = "web"
  }
}
