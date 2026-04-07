# config.py — INTENTIONALLY VULNERABLE — for lab use only
# This file demonstrates common secret exposure patterns.
# Do not use any of these values in production — they are examples only.

# Pattern 1: AWS credentials hardcoded in configuration
# Rule triggered: aws-access-token
AWS_ACCESS_KEY_ID = "AKIAIOSFODNN7EXAMPLE"
AWS_SECRET_ACCESS_KEY = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
AWS_REGION = "us-east-1"

# Pattern 2: Database connection string with credentials
# Rule triggered: generic-api-key or postgres-password
DATABASE_URL = "postgresql://admin:Sup3rS3cr3tP@ssw0rd!@db.example.com:5432/appdb"

# Pattern 3: Intentional false positive — base64-encoded test fixture (not a secret)
# This should be suppressed using gitleaks allowlist configuration
TEST_FIXTURE_ENCODED = "dGVzdC1maXh0dXJlLWRhdGEtbm90LWEtc2VjcmV0LXZhbHVlLWZvci1sYWI="
