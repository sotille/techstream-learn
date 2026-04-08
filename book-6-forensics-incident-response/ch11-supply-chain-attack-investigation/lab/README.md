# Lab 11 — Supply Chain Attack Investigation

**Estimated time:** 75–90 minutes
**Difficulty:** Advanced
**Prerequisites:** Completion of Lab 9 (Pipeline Compromise Investigation) or familiarity with the five-phase investigation methodology; familiarity with npm/Python package ecosystems; ability to read lockfile formats

---

## Objective

By the end of this lab you will be able to:
- Use lockfile evidence to determine which pipeline executions ingested a malicious dependency version
- Apply SBOM records to trace contaminated artifacts to deployment targets
- Determine the blast radius of a supply chain attack across multiple environments
- Produce an artifact quarantine list and a draft external notification

---

## Scenario: The codec-utils Compromise

On 2024-09-18, the security team at Thornfield Systems received a notification from a threat intelligence vendor: the npm package `codec-utils`, widely used in media processing applications, had been found to contain a backdoor in versions `3.4.0` through `3.4.6`. The malicious versions were published on 2024-09-03 and removed by the npm registry maintainers on 2024-09-17 after a 14-day exposure window. The backdoor exfiltrates the `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` environment variables via an HTTP POST on first package load.

Thornfield's `media-processor` service uses `codec-utils`. You are the security engineer assigned to determine the impact on Thornfield's environment.

---

## Evidence Set

### Evidence A — Package Lockfiles (git history extract)

The `package-lock.json` from the `media-processor` repository shows the following `codec-utils` version history in git:

```
commit a1b2c3d  2024-08-29  "chore: update dependencies"
  codec-utils: 3.3.9

commit e4f5a6b  2024-09-05  "feat: add HDR tone-mapping support"
  codec-utils: 3.4.2  <-- introduced

commit 9c8d7e6  2024-09-11  "fix: memory leak in transcoding pipeline"
  codec-utils: 3.4.4  <-- updated within malicious range

commit 2f1g0h9  2024-09-17  "chore: bump codec-utils to 3.5.0"
  codec-utils: 3.5.0  <-- cleaned version (published same day as removal)
```

### Evidence B — CI/CD Build Records

GitHub Actions workflow runs for `media-processor` (main branch, production builds only):

| Run ID | Triggered At (UTC) | Commit SHA | codec-utils Version | Artifact Tag | Deployed To |
|--------|-------------------|------------|--------------------|-----------:|-------------|
| 8841 | 2024-09-05T16:22:00Z | e4f5a6b | 3.4.2 | v2.8.0 | staging |
| 8851 | 2024-09-06T09:14:00Z | e4f5a6b | 3.4.2 | v2.8.0-p1 | staging, production |
| 8862 | 2024-09-08T11:00:00Z | e4f5a6b | 3.4.2 | v2.8.1 | staging, production |
| 8879 | 2024-09-11T14:45:00Z | 9c8d7e6 | 3.4.4 | v2.9.0 | staging |
| 8883 | 2024-09-12T10:30:00Z | 9c8d7e6 | 3.4.4 | v2.9.0-rc1 | staging |
| 8891 | 2024-09-13T15:00:00Z | 9c8d7e6 | 3.4.4 | v2.9.1 | staging, production |
| 8897 | 2024-09-17T17:00:00Z | 2f1g0h9 | 3.5.0 | v2.9.2 | staging, production |

### Evidence C — SBOM Records

SBOMs were generated for production builds using `syft`. Excerpts for the relevant builds:

```
Build v2.8.0-p1 (Run 8851):
  - codec-utils@3.4.2 (npm)
  - ffmpeg-node@5.1.0 (npm)
  - aws-sdk@2.1450.0 (npm)

Build v2.8.1 (Run 8862):
  - codec-utils@3.4.2 (npm)
  - ffmpeg-node@5.1.0 (npm)
  - aws-sdk@2.1450.0 (npm)

Build v2.9.1 (Run 8891):
  - codec-utils@3.4.4 (npm)
  - ffmpeg-node@5.1.1 (npm)
  - aws-sdk@2.1452.0 (npm)

Build v2.9.2 (Run 8897):
  - codec-utils@3.5.0 (npm)
  - ffmpeg-node@5.1.1 (npm)
  - aws-sdk@2.1452.0 (npm)
```

### Evidence D — AWS CloudTrail (IAM events for the media-processor ECS task role)

```json
[
  {
    "eventTime": "2024-09-06T09:22:14Z",
    "eventName": "AssumeRole",
    "requestParameters": {
      "roleArn": "arn:aws:iam::555444333222:role/media-processor-task-role"
    },
    "sourceIPAddress": "203.0.113.55",
    "userAgent": "aws-sdk-nodejs/2.1450.0"
  },
  {
    "eventTime": "2024-09-06T09:22:17Z",
    "eventName": "GetCallerIdentity",
    "sourceIPAddress": "203.0.113.55"
  },
  {
    "eventTime": "2024-09-06T09:22:18Z",
    "eventName": "ListRoles",
    "sourceIPAddress": "203.0.113.55"
  }
]
```

The ECS task's expected source IP range is `10.0.8.0/24` (internal VPC). The IP `203.0.113.55` is external.

---

## Exercise 1 — Q1 and Q2: Scope and Ingestion (20 minutes)

1. Based on the lockfile history (Evidence A), what is the exact date range during which a malicious version of `codec-utils` was present in the codebase?

2. Using the build records (Evidence B), list every build run that ingested a malicious `codec-utils` version. For each, state the version, the artifact tag produced, and the environments it was deployed to.

3. Identify the first production deployment that included the malicious package. How long did it remain in production before the clean version was deployed?

4. Were there any builds during the malicious window that did NOT ingest a malicious version? Explain.

---

## Exercise 2 — Q3: What Did the Malicious Package Do? (15 minutes)

The threat intelligence report states the backdoor exfiltrates `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` via HTTP POST on first package load.

1. In an ECS container deployment, how would `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` typically be available to the running container? (Consider both static key injection and IAM task roles.)

2. The CloudTrail evidence (Evidence D) shows API calls from an external IP on 2024-09-06 at 09:22. This is 8 minutes after the first production deployment of v2.8.0-p1. What does this timeline suggest?

3. The `GetCallerIdentity` and `ListRoles` calls from the external IP are consistent with initial reconnaissance using stolen credentials. What further actions would you expect the attacker to attempt using the ECS task role credentials? What limits their blast radius?

---

## Exercise 3 — Q4: Blast Radius Determination (20 minutes)

1. Using the SBOM records (Evidence C), list all container image versions that are contaminated (include the malicious `codec-utils` version).

2. For each contaminated image that was deployed to production, state:
   - The date range during which it was in production
   - Whether the container was actively serving requests during that period
   - The ECS task role permissions (from context: the task role has `s3:GetObject` on the media assets bucket and `secretsmanager:GetSecretValue` for `media-processor/*` secrets)

3. Based on the CloudTrail evidence, what specific credentials are confirmed as compromised? What additional credentials may be compromised based on the task role's permissions?

4. Produce an artifact quarantine list. For each artifact, state: quarantine action (pull from production, revoke, rotate), urgency (immediate / next maintenance window), and rationale.

---

## Exercise 4 — External Notification Draft (15 minutes)

Thornfield Systems' legal team has asked you to draft the technical portion of a potential external notification. The notification may be required if customer data was accessible to the compromised task role credentials.

Write the technical portion of the notification (150–200 words) covering:
- Nature of the incident (what type of attack, what was compromised)
- Timeline (when did exposure begin and end)
- What data may have been accessible
- What actions have been taken
- What affected parties should do (if applicable)

Do not over-state certainty. Use phrases like "may have been accessible" and "we are investigating" where the evidence is incomplete.

---

## Summary

Supply chain attack investigations are fundamentally an artifact tracing problem. The lockfile provides the evidence of when the malicious artifact entered the codebase; build records connect that ingestion to specific artifacts; SBOMs connect artifacts to deployments; CloudTrail connects deployments to runtime impact.

The codec-utils scenario demonstrates that a 14-day supply chain exposure window can result in multiple contaminated production deployments across multiple image versions — and that the backdoor's runtime behavior (credential exfiltration) may manifest almost immediately after the first deployment.

The SBOM is the single most important artifact for supply chain investigations. Without it, tracing which deployments used the malicious version requires reconstructing the dependency graph from build logs — a time-consuming and error-prone process.

---

## Further Reading

- Chapter 8 (in the book): Supply Chain Forensic Evidence — complete evidence taxonomy for supply chain investigations
- Chapter 12: Identity and Credential Compromise — follow-on investigation for the exfiltrated ECS task role credentials
- [CISA Supply Chain Risk Management](https://www.cisa.gov/supply-chain-risk-management) — regulatory and notification guidance
- [CycloneDX SBOM specification](https://cyclonedx.org/specification/overview/) — SBOM format reference
