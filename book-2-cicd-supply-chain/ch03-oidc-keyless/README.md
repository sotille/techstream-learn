# Chapter 3 — OIDC Keyless Authentication: Eliminating Long-Lived Credentials

## What You Will Learn

Long-lived credentials stored in CI/CD secrets are a persistent security liability. Every long-lived IAM key, service account JSON file, or API token in a secrets store is a credential that can be stolen, leaked in build logs, committed to source code by accident, or left in place long after it should have been rotated. OIDC federation eliminates the need to store these credentials at all.

By the end of this chapter, you will understand:

- Why long-lived credentials in CI/CD pipelines are the highest-risk secrets in most organizations
- How OpenID Connect (OIDC) federation works: the mechanics of token issuance, trust establishment, and credential exchange
- How to configure OIDC federation for GitHub Actions with AWS, Azure, and GCP
- How to scope trust relationships to specific repositories, branches, environments, and workflows
- How to audit OIDC token exchanges and alert on anomalous patterns
- How to migrate from long-lived credentials to OIDC without disrupting running pipelines

## Why It Matters

In 2023, CircleCI disclosed a security incident in which a malicious actor had obtained customer CI secrets stored in the platform. Any organization that stored cloud credentials in CircleCI had to assume those credentials were compromised and rotate them immediately. This is the inherent problem with long-lived credentials: once stolen, they remain valid until explicitly rotated — and rotation is often delayed or incomplete.

OIDC federation changes the threat model entirely. Instead of storing a credential that a bad actor could steal and use indefinitely, OIDC issues a fresh, short-lived credential for each pipeline job. There is nothing persistent to steal. If the OIDC token for one job were intercepted, it would expire within 15–60 minutes and could only be used from the CI platform's infrastructure — not from an attacker's own systems.

## Key Concepts

**The credential storage problem**: Conventional CI/CD pipelines store cloud credentials (AWS access keys, Azure service principal secrets, GCP service account JSON files) as pipeline secrets. These credentials are long-lived by design — they remain valid for months or years and grant broad cloud access to whoever holds them.

**OIDC federation flow**:
1. Pipeline job starts → CI platform issues a signed JWT token containing claims about the job (repository, branch, environment, workflow)
2. Pipeline exchanges the JWT with the cloud provider's STS endpoint
3. Cloud provider verifies the JWT signature using the CI platform's published JWKS endpoint, checks the claims against the IAM trust policy
4. Cloud provider issues short-lived session credentials (15–60 minutes)
5. Pipeline uses the short-lived credentials → they expire when the job ends

**Subject claim scoping**: The `sub` claim in the OIDC JWT identifies the specific context of the pipeline job. Trust policies should use the most restrictive subject claim possible:
- `repo:org/repo:*` — any job in this repository (appropriate for build/test)
- `repo:org/repo:ref:refs/heads/main` — main branch only (appropriate for staging)
- `repo:org/repo:environment:production` — production environment with approval gate (appropriate for production)

**Separation of build and deploy roles**: Each pipeline role should have only the permissions needed for its specific function. A build role needs ECR push access; it does not need ECS deployment permissions. A deploy role needs ECS update access; it does not need ECR write access. Separate roles enforce least privilege and limit the blast radius of any single role being misused.

## What Changes for Developers

From a developer perspective, OIDC federation is largely invisible. The pipeline configuration changes (replacing `aws-access-key-id: ${{ secrets.AWS_KEY }}` with a role ARN), but pipeline behavior is unchanged. The credentials are still available to the pipeline steps that need them — they are just obtained differently.

The main developer-visible change is that credentials expire after the job. Long-running jobs (more than 60 minutes) need to request credential refreshes or use assume-role patterns that extend the session. For most pipelines, this is not an issue.

## Framework Reference

This chapter is based on the Secure CI/CD Reference Architecture:

- [OIDC Federation Guide — Full Configuration Reference](../../secure-ci-cd-reference-architecture/docs/oidc-federation-guide.md)
- [Threat Model — Credential Theft Section](../../secure-ci-cd-reference-architecture/docs/threat-model.md)

## Lab

See [lab/README.md](lab/README.md) for the hands-on exercise: **Configuring OIDC Federation for GitHub Actions**.
