# Chapter 12 — Identity and Credential Compromise Investigation

## What You Will Learn

This chapter covers the investigation of incidents involving compromised machine identities in pipeline and cloud environments. You will learn to trace the lifecycle of a compromised credential — from initial exposure through use — using cloud provider audit logs, pipeline identity records, and OIDC token metadata. You will also learn the response actions that limit blast radius and the evidence collection procedures that preserve the identity audit trail before tokens expire.

## Why This Matters

Pipelines operate almost entirely through machine identities: OIDC federation tokens, IAM roles, service account keys, deploy keys, API tokens. These identities are granted the permissions needed to perform legitimate pipeline operations — which often include reading secrets, pushing artifacts, and deploying to cloud environments. When a machine identity is compromised, an attacker inherits those permissions for the token's lifetime.

Machine identity investigations are time-constrained in a way that endpoint investigations are not. OIDC tokens typically expire within an hour. The cloud API calls made with a compromised token are recorded in the cloud provider audit log, but the retention window for those logs may be as short as 90 days. If investigation does not begin quickly, the evidence window closes.

## The Machine Identity Lifecycle

**Issuance:** Pipeline systems receive identity through OIDC federation (GitHub Actions, GitLab CI, CircleCI OIDC), long-lived service account keys, or static tokens. The issuance event is recorded in the pipeline system's audit log and (for OIDC) in the cloud provider's identity service.

**Use:** Every cloud API call made with the identity is recorded in the cloud provider audit log with the full token claims, the specific action requested, the resource targeted, and whether the request was permitted or denied.

**Expiry/Rotation:** OIDC tokens expire automatically. Service account keys must be rotated explicitly. The rotation event is recorded in the cloud provider's IAM audit log.

**Compromise indicators:** Unusually high API call volume, API calls to resource types not normally accessed by the identity, calls from unexpected source IPs (especially non-pipeline IP ranges), calls made outside normal pipeline execution windows, calls that trigger IAM permission boundary violations.

## Key Evidence Sources

- Cloud provider IAM audit logs (CloudTrail, Cloud Audit Logs, Azure Activity Log): every API call with full token claims
- OIDC token issuance records: pipeline-side record of which job issued which token with which claims
- Pipeline job logs: correlation between job execution and the OIDC token the job received
- Secrets management audit logs (Vault, AWS Secrets Manager): records of secret access by machine identity
- Git service deploy key audit logs: per-key operation logs showing what the key was used to read or write

## What You Will Practice

This chapter's lab covers two investigation exercises:

**Exercise 1** — OIDC token abuse: given CloudTrail logs from a 4-hour window, trace the actions of a compromised OIDC token from issuance through a sequence of API calls, identify the specific permissions abused, and determine whether the abuse exceeded the scope of the pipeline's legitimate operations.

**Exercise 2** — Long-lived credential exposure: given a scenario where a service account key was accidentally committed to a public repository, reconstruct the timeline of credential use (including any use by the legitimate pipeline and any use by external actors) and determine the blast radius using IAM audit log evidence.

## Lab

See [lab/README.md](lab/README.md) for the guided identity and credential compromise investigation exercises.
