# Lab 3 — Forensics Readiness Score Assessment

**Estimated time:** 60–75 minutes
**Difficulty:** Intermediate
**Prerequisites:** Completion of Lab 1 (or familiarity with the five structural IR gaps); basic familiarity with CI/CD pipeline configuration (GitHub Actions or equivalent)

---

## Objective

By the end of this lab you will be able to:
- Apply the five FRS dimensions to a real pipeline environment configuration
- Score each dimension with written justification and supporting evidence
- Produce a prioritized remediation plan with chapter references
- Communicate a readiness gap to a non-technical stakeholder in two sentences per gap

---

## Reference Environment: Streamline Corp

Streamline Corp is a Series B SaaS company with a 40-person engineering team. Their pipeline is built on GitHub Actions with deployments to AWS ECS. The following artifacts describe their current pipeline configuration.

### GitHub Actions Workflow (excerpt)

```yaml
name: build-and-deploy
on:
  push:
    branches: [main]

permissions:
  id-token: write
  contents: read

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Build and push image
        run: |
          docker build -t $IMAGE_TAG .
          docker push $IMAGE_TAG

      - name: Deploy to ECS
        run: |
          aws ecs update-service --cluster prod --service api --force-new-deployment

  notify:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - name: Post deployment status to Slack
        run: curl -X POST $SLACK_WEBHOOK -d "{\"text\":\"Deployed $GITHUB_SHA\"}"
```

### AWS Configuration Notes (from their infrastructure-as-code README)

- CloudTrail enabled on the account; logs shipped to S3 with 90-day lifecycle rule, then deleted
- S3 access logging: enabled on the artifact bucket only; 30-day retention
- ECS task execution role has `secretsmanager:GetSecretValue` permission for all secrets in the account
- No SBOM generation step in the pipeline
- No artifact signing; images pushed by tag (`v1.2.3`) without digest pinning in ECS task definition
- GitHub Actions log retention: default (90 days)
- No centralized log aggregation; each AWS service logs to its own destination

### Incident Response Documentation

- Last IR tabletop exercise: 18 months ago (before the current pipeline architecture was in place)
- IR runbook covers credential compromise and DDoS; no pipeline-specific runbook exists
- On-call rotation covers availability incidents; security incidents escalate to the CISO on-call

---

## Exercise 1 — Score Each FRS Dimension (40 minutes)

Using the configuration artifacts above, score each of the five FRS dimensions. For each dimension, provide:
- Your score (0, 1, or 2)
- The specific configuration evidence that supports your score
- The gap that prevents a higher score (if applicable)

**Scoring rubric:**
- **0** — No control present; evidence category unavailable or untested
- **1** — Partial control; significant gaps that would impede investigation
- **2** — Full control; evidence complete, durable, and accessible within tested procedures

### Dimension 1 — Evidence Completeness

The five pipeline evidence categories are: (a) build provenance, (b) artifact integrity records, (c) deployment records, (d) identity/authorization events, (e) runtime behavior.

| Evidence Category | Present? | Notes |
|-------------------|----------|-------|
| Build provenance | | |
| Artifact integrity records | | |
| Deployment records | | |
| Identity/authorization events | | |
| Runtime behavior | | |

**EC Score:** __ / 2
**Justification:**

---

### Dimension 2 — Tamper Resistance

**TR Score:** __ / 2
**Justification:**

---

### Dimension 3 — Retention and Availability

**RA Score:** __ / 2
**Justification:**

---

### Dimension 4 — Correlation Capability

**CC Score:** __ / 2
**Justification:**

---

### Dimension 5 — Tested Response Procedures

**TP Score:** __ / 2
**Justification:**

---

**Total FRS: __ / 10**

---

## Exercise 2 — Prioritized Remediation Plan (20 minutes)

For each dimension scored below 2, produce a remediation item with the following fields:

| Dimension | Current Score | Target Score | Remediation Action | Effort | Chapter Reference |
|-----------|--------------|--------------|-------------------|--------|-------------------|
| | | | | Low / Med / High | Ch. X |

Order the remediation items by the following priority formula:
**Priority = (2 − current score) × time_sensitivity**

Where time_sensitivity is:
- 3 = evidence expires within days if not addressed
- 2 = evidence expires within weeks
- 1 = evidence does not expire but capability is missing

---

## Exercise 3 — Executive Summary (10 minutes)

Write a two-sentence summary for each gap suitable for a briefing to a non-technical executive. Each sentence should convey: (1) what the gap means in plain language, and (2) what the consequence would be during a real investigation.

**Example:**
"We currently have no reliable way to confirm whether the software artifacts we deploy to production have been tampered with since they were built. In a supply chain attack scenario, this means we cannot rule out that customers received compromised software without conducting a full manual audit of each deployment."

Write your summaries for each dimension scored below 2.

---

## Summary

The Forensics Readiness Score turns forensic readiness from an abstract aspiration into a measurable state. Streamline Corp's configuration illustrates a pattern common in fast-growing engineering organizations: evidence is being generated, but it is incomplete, insufficiently durable, and not correlated across systems. The gap between "we have some logs" and "we can investigate a pipeline compromise" is not small — but it is closeable with a structured prioritization of the controls covered in Chapters 5–8.

---

## Further Reading

- Chapter 5 (in the book): Immutable Audit Trails — closing EC and TR gaps
- Chapter 6: Pipeline Forensic Evidence — closing EC and CC gaps
- Chapter 7: Cloud and Container Forensic Artifacts — closing RA gaps for cloud evidence
- Chapter 8: Supply Chain Forensic Evidence — closing EC gap for supply chain opacity
