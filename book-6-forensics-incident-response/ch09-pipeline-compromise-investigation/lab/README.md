# Lab 9 — Pipeline Compromise Investigation

**Estimated time:** 75–90 minutes
**Difficulty:** Intermediate–Advanced
**Prerequisites:** Completion of Labs 5 and 6 (or familiarity with pipeline evidence types and collection procedures); ability to read JSON log formats; familiarity with GitHub Actions workflow structure

---

## Objective

By the end of this lab you will be able to:
- Apply the five-phase pipeline compromise investigation methodology to a realistic evidence set
- Reconstruct an attack timeline from distributed, partial evidence
- Determine which build artifacts are potentially contaminated and which are clean
- Produce a one-page investigation summary suitable for a regulatory notification

---

## Scenario: The Meridian Build System Incident

Meridian Technologies operates a SaaS analytics platform. On 2024-06-12 at 09:47 UTC, their security monitoring system detected an anomalous outbound HTTPS connection from their GitHub Actions runner IP range to an external IP address (`198.51.100.47`) not associated with any known dependency or service endpoint.

The following evidence artifacts have been collected and are available for investigation. All timestamps are UTC.

---

## Evidence Set

### Evidence A — GitHub Actions Workflow Run Log (excerpt)

```
2024-06-12T09:31:02Z  Run actions/checkout@v4
2024-06-12T09:31:08Z  Post checkout: cleaning workspace
2024-06-12T09:31:09Z  Run setup-node
2024-06-12T09:31:14Z  Run npm ci
2024-06-12T09:31:47Z  ##[group]Run npm run build
2024-06-12T09:32:51Z  ##[endgroup]
2024-06-12T09:32:52Z  Run npm run test
2024-06-12T09:34:01Z  Tests passed: 847 passed, 0 failed
2024-06-12T09:34:02Z  Run docker/build-push-action@v5
2024-06-12T09:41:18Z  Image pushed: registry.meridian.io/api:sha-a3f9c1e
2024-06-12T09:41:19Z  Run actions/upload-artifact
2024-06-12T09:41:23Z  Artifact uploaded: build-output-a3f9c1e
2024-06-12T09:41:24Z  Run deploy-to-staging (internal action)
2024-06-12T09:45:12Z  Staging deployment complete
2024-06-12T09:45:13Z  Run run-integration-tests
2024-06-12T09:46:58Z  Integration tests passed
2024-06-12T09:46:59Z  Run approve-production-deployment (requires manual approval)
2024-06-12T09:47:03Z  [ANOMALY DETECTED BY SIEM] Outbound connection to 198.51.100.47:443
2024-06-12T09:47:08Z  Approval gate: pending
2024-06-12T09:47:31Z  Production deployment: BLOCKED by security team
```

### Evidence B — CloudTrail Events (relevant subset)

```json
[
  {
    "eventTime": "2024-06-12T09:34:28Z",
    "eventName": "AssumeRoleWithWebIdentity",
    "userAgent": "actions/oidc-client",
    "requestParameters": {
      "roleArn": "arn:aws:iam::123456789012:role/github-actions-build",
      "roleSessionName": "meridian-api-build-run-9283746"
    },
    "responseElements": {
      "credentials": {
        "sessionToken": "[REDACTED]",
        "expiration": "2024-06-12T10:34:28Z"
      }
    },
    "sourceIPAddress": "192.0.2.15"
  },
  {
    "eventTime": "2024-06-12T09:41:05Z",
    "eventName": "GetSecretValue",
    "userIdentity": {
      "sessionContext": {
        "sessionIssuer": {
          "arn": "arn:aws:iam::123456789012:role/github-actions-build"
        }
      }
    },
    "requestParameters": {
      "secretId": "arn:aws:secretsmanager:us-east-1:123456789012:secret:prod/database-credentials"
    },
    "sourceIPAddress": "192.0.2.15"
  },
  {
    "eventTime": "2024-06-12T09:47:01Z",
    "eventName": "GetSecretValue",
    "userIdentity": {
      "sessionContext": {
        "sessionIssuer": {
          "arn": "arn:aws:iam::123456789012:role/github-actions-build"
        }
      }
    },
    "requestParameters": {
      "secretId": "arn:aws:secretsmanager:us-east-1:123456789012:secret:prod/database-credentials"
    },
    "sourceIPAddress": "192.0.2.15"
  }
]
```

### Evidence C — npm Dependency Audit Log (excerpt from `npm ci` output)

```
added 847 packages in 32s

14 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities

--- Build tool version check ---
Loaded: build-optimizer@2.1.4
Loaded: asset-minifier@1.8.0
Loaded: source-map-generator@3.0.1
Loaded: meridian-internal-utils@4.2.1
```

### Evidence D — External Threat Intelligence (provided by SIEM)

The IP address `198.51.100.47` was observed in threat intelligence feeds on 2024-06-08 as a C2 server associated with the `build-optimizer` npm package versions 2.1.0–2.1.4. The malicious code in those versions calls home during the build process and exfiltrates environment variables.

### Evidence E — Artifact Digest Records

```
Image pushed at: 2024-06-12T09:41:18Z
Digest: sha256:8f2a4c1e9b3d5f7a2c4e6b8d0f2a4c6e8b0d2f4a6c8e0b2d4f6a8c0e2b4d6f8

Previous build (2024-06-11T14:22:07Z):
Digest: sha256:1a3b5c7d9e1f3a5b7c9d1e3f5a7b9c1d3e5f7a9b1c3d5e7f9a1b3c5d7e9f1a3

Signing status: UNSIGNED (cosign not configured for this repository)
```

---

## Exercise 1 — Phase 1: Scope Assessment (15 minutes)

Using the evidence set above, answer the following:

1. What is the suspected initial access vector? (What component was compromised and how?)

2. What is the time window of potential compromise? (When could the malicious activity have begun and ended?)

3. List the pipeline components that are within scope for this investigation.

4. Which artifacts produced during the incident window must be treated as potentially contaminated?

---

## Exercise 2 — Phase 2 and 3: Evidence Preservation and Timeline Reconstruction (25 minutes)

**Part A — Evidence Preservation Gaps**

Based on the evidence set provided:

1. What evidence is missing that you would want to have for a complete investigation?
2. For each missing evidence type, state whether it is missing because it was never collected, because it has expired, or because the service does not produce it by default.
3. What would have provided the most valuable missing evidence?

**Part B — Attack Timeline**

Reconstruct the attack timeline using the evidence provided. Order events chronologically and annotate each event as: (A) attacker action, (P) normal pipeline activity, or (U) unknown/ambiguous.

Use this format:

| Time (UTC) | Event | Classification | Evidence Source | Confidence |
|-----------|-------|---------------|----------------|-----------|
| 09:31:02 | Checkout action executed | P | Evidence A | High |
| ... | ... | ... | ... | ... |

Your timeline must include at least 10 entries and cover the full incident window.

---

## Exercise 3 — Phase 4: Artifact Contamination Analysis (15 minutes)

1. The container image with digest `sha256:8f2a4c1e...` was built during the incident window. Based on the available evidence, what is your assessment of whether this image is contaminated?

2. The production deployment was blocked. If it had not been blocked, what would the consequence have been? What specific action would you recommend for the staging environment where the image was deployed?

3. The `build-optimizer` package version 2.1.4 exfiltrates environment variables. Based on the CloudTrail evidence, what specific credentials may have been exfiltrated, and what immediate remediation actions are required?

4. Draft a list of all deployments and environments that must be treated as potentially compromised.

---

## Exercise 4 — Phase 5: Investigation Summary (15 minutes)

Write a one-page investigation summary (approximately 400 words) covering:

- Incident overview: what happened, when, and how
- Confirmed attacker actions (with evidence citations)
- Probable attacker actions (with confidence level)
- Artifact contamination scope
- Immediate remediation actions required
- Evidentiary gaps (what cannot be determined from available evidence)

This summary will be reviewed by your organization's legal team for potential regulatory notification. Write it with that audience in mind: factual, precise, and explicit about what is established versus inferred.

---

## Summary

Pipeline compromise investigations require a different evidence mindset than endpoint investigations. The evidence is distributed, much of it ephemeral, and the attacker's entry point is often a dependency rather than a direct intrusion. The five-phase methodology provides a structured approach that ensures evidence is preserved before it expires, scope is established before investigation resources are committed, and findings are documented with appropriate confidence levels.

The Meridian scenario illustrates how a supply chain attack (compromised npm package) enables credential exfiltration through a legitimate pipeline execution. The investigation reveals the full blast radius — which artifacts are contaminated, which credentials are exposed — only when multiple evidence sources (job logs, CloudTrail, threat intelligence) are correlated.

---

## Further Reading

- Chapter 11 (in the book): Supply Chain Attack Investigation — detailed methodology for the supply chain vector used in this scenario
- Chapter 12: Identity and Credential Compromise Investigation — follow-on investigation for the exfiltrated credentials
- Chapter 8: Supply Chain Forensic Evidence — lockfile and dependency evidence sources for supply chain investigations
