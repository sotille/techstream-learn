# Lab 5 — Immutable Audit Trails

**Estimated time:** 60–75 minutes
**Difficulty:** Intermediate
**Prerequisites:** Familiarity with S3 or equivalent object storage; basic understanding of CI/CD pipeline configuration; familiarity with JSON log formats

---

## Objective

By the end of this lab you will be able to:
- Explain the immutability guarantees provided by each audit trail pattern and their limitations
- Configure a pipeline to emit structured audit events to a write-once S3 bucket with Object Lock
- Verify the immutability guarantee by confirming that an overwrite attempt is rejected
- Interpret a Rekor transparency log entry and describe what it establishes forensically

---

## Exercise 1 — S3 Object Lock Audit Trail (35 minutes)

### Background

S3 Object Lock (WORM mode) prevents objects from being overwritten or deleted for a configurable retention period. For pipeline audit trails, this provides a tamper-resistance guarantee that is enforceable even if the pipeline's IAM identity is compromised: the compromised identity cannot delete the audit records that document its own activity.

### Part A — Bucket Configuration

The following Terraform snippet configures an S3 bucket for pipeline audit log storage with Object Lock enabled.

```hcl
resource "aws_s3_bucket" "pipeline_audit" {
  bucket = "pipeline-audit-logs-${var.account_id}"

  object_lock_enabled = true
}

resource "aws_s3_bucket_object_lock_configuration" "pipeline_audit" {
  bucket = aws_s3_bucket.pipeline_audit.id

  rule {
    default_retention {
      mode = "COMPLIANCE"
      days = 365
    }
  }
}

resource "aws_s3_bucket_versioning" "pipeline_audit" {
  bucket = aws_s3_bucket.pipeline_audit.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "pipeline_audit" {
  bucket = aws_s3_bucket.pipeline_audit.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

**Questions:**

1. What is the difference between COMPLIANCE mode and GOVERNANCE mode Object Lock? Which is more appropriate for a forensic audit trail that must satisfy a regulatory obligation, and why?

2. The configuration above uses a `default_retention` of 365 days. What factors should drive the choice of retention period for a pipeline audit trail? List at least three.

3. This bucket requires S3 versioning to be enabled for Object Lock to work. What does S3 versioning provide beyond Object Lock? Does it add additional forensic value?

### Part B — Pipeline Audit Event Schema

A pipeline audit event for an immutable audit trail should be self-describing and contain sufficient information to reconstruct the event without reference to external systems.

Design a JSON schema for a pipeline job completion audit event. Your schema must include fields for:
- Pipeline system and job identifier
- Repository, branch, and commit SHA
- Start time and end time (ISO 8601, with timezone)
- Exit status (success / failure / cancelled)
- Artifact outputs: name, digest (SHA-256), registry URL
- Identity: the OIDC claims of the identity that executed the job (issuer, subject, audience)
- A field reserved for a signature over the event payload (to be populated by the signing step)

Write the schema as a JSON example with realistic placeholder values.

### Part C — Immutability Verification

Once audit events are written to the Object Lock bucket, the immutability guarantee should be tested. The following AWS CLI command attempts to overwrite an existing object:

```bash
aws s3 cp audit-event-new.json \
  s3://pipeline-audit-logs-123456789/2024/01/15/build-job-7823.json \
  --profile pipeline-writer
```

**Questions:**

1. If Object Lock is correctly configured in COMPLIANCE mode with an active retention period, what error will this command return?

2. The pipeline's IAM role (`pipeline-writer`) needs permission to write new audit events but must not be able to overwrite or delete existing events. Write the IAM policy JSON that grants `s3:PutObject` while explicitly denying `s3:DeleteObject` and `s3:PutObject` on existing versions.

3. An attacker who compromises the pipeline IAM role attempts to cover their tracks by deleting the audit event that records their unauthorized action. Explain exactly why this fails given the Object Lock configuration above, referencing the specific S3 mechanism that prevents it.

---

## Exercise 2 — Rekor Transparency Log Verification (25 minutes)

### Background

Rekor is the Sigstore transparency log for software supply chain artifacts. When a pipeline artifact is signed with Sigstore (`cosign sign`), a record is written to the Rekor log. The record is immutable (entries can be added but not deleted or modified) and publicly verifiable. During an investigation, Rekor entries provide an independently verifiable record of when an artifact was signed and by which identity.

### A Sample Rekor Entry

The following is an abbreviated representation of a Rekor log entry for a container image:

```json
{
  "logIndex": 98234712,
  "logID": "c0d23d6ad406973f9559f3ba2d1ca01f84147d8ffc5b8445c224f98b9591801d",
  "body": {
    "kind": "hashedrekord",
    "apiVersion": "0.0.1",
    "spec": {
      "signature": {
        "content": "MEYCIQDx...",
        "publicKey": {
          "content": "LS0tLS1C..."
        }
      },
      "data": {
        "hash": {
          "algorithm": "sha256",
          "value": "a3f2c1e8d4b7906f3e2c15a8d4b2f7c9e1a3f5d2b4e6c8a1d3f5b7e9c2a4f6"
        }
      }
    }
  },
  "integratedTime": 1705334400,
  "verification": {
    "signedEntryTimestamp": "MEQCIBx..."
  }
}
```

**Questions:**

1. The `integratedTime` field contains a Unix timestamp. Convert this to a human-readable datetime and explain what this timestamp represents — specifically, is it the time the artifact was created, the time the signature was generated, or the time the entry was accepted into the log?

2. What does the `signedEntryTimestamp` field prove? Who signs it, and how does this prevent an adversary from backdating a Rekor entry?

3. During an investigation, you want to verify that a specific container image digest (`sha256:a3f2c1e8...`) was known to the organization's signing infrastructure before a specific date. Explain how you would use the Rekor entry above to make that determination, and what limitations apply to the conclusion.

4. An attacker who compromised a pipeline signing key could create a Rekor entry for a malicious artifact, making it appear legitimately signed. What property of the Rekor log ensures that this entry is visible to defenders, and how would a continuous monitoring system detect it?

---

## Summary

Immutable audit trails are a prerequisite for pipeline forensics, not a nice-to-have. Without tamper-resistant evidence, an attacker who compromises a pipeline component can cover their tracks — and an investigation that cannot rule out evidence tampering cannot produce findings with high confidence.

Object Lock provides infrastructure-level immutability that survives even a full IAM credential compromise. Rekor provides cryptographically verifiable provenance records that are publicly auditable and cannot be backdated. Together they address the Tamper Resistance dimension of the Forensics Readiness Score.

The next chapter (Chapter 6) builds on these foundations to catalog all the evidence types a pipeline produces and the specific collection procedures for each.

---

## Further Reading

- [Sigstore / Rekor documentation](https://docs.sigstore.dev/rekor/overview/) — Rekor log entry format and verification procedures
- [AWS S3 Object Lock documentation](https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lock.html) — COMPLIANCE vs GOVERNANCE mode, retention period configuration
- Chapter 3 (in the book): Forensics Readiness Score — Tamper Resistance dimension scoring
