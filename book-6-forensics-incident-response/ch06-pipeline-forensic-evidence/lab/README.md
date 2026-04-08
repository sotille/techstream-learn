# Lab 6 — Pipeline Forensic Evidence Collection

**Estimated time:** 60–75 minutes
**Difficulty:** Intermediate
**Prerequisites:** Familiarity with GitHub Actions (or equivalent CI/CD); basic AWS CLI / cloud console familiarity; completion of Lab 3 (FRS) or familiarity with the five evidence categories

---

## Objective

By the end of this lab you will be able to:
- Map each pipeline evidence category to its specific source location and default retention window
- Produce an evidence collection checklist ordered by expiry urgency for a given incident window
- Write a pipeline job step that externalizes critical build evidence to persistent storage before runner termination
- Identify which evidence categories are unavailable in a given pipeline configuration

---

## Exercise 1 — Evidence Inventory and Expiry Mapping (25 minutes)

The following table describes the pipeline components in use at a fictional organization. For each component, use your knowledge of each service's default behavior to complete the evidence inventory.

| Pipeline Component | Evidence Type | Default Location | Default Retention | Evidence Available 1 hr After Incident | Available 72 hrs After | Available 30 Days After |
|-------------------|---------------|-----------------|------------------|----------------------------------------|------------------------|------------------------|
| GitHub Actions | Job logs | GitHub UI / API | 90 days | Yes | Yes | Yes |
| GitHub Actions | Runner process artifacts | Local runner filesystem | Until runner recycles | ? | ? | ? |
| GitHub Actions | Workflow run metadata (trigger, actor, SHA) | GitHub API | 90 days | Yes | Yes | Yes |
| AWS ECR | Image push history | ECR API | Indefinite | Yes | Yes | Yes |
| AWS ECR | Image pull records | ECR API | Not available by default | N/A | N/A | N/A |
| AWS CloudTrail | IAM role assumption events | S3 (CloudTrail bucket) | Configurable (default 90 days) | Yes | Yes | Yes |
| AWS CloudTrail | ECS deployment API calls | S3 (CloudTrail bucket) | Configurable | Yes | Yes | Yes |
| AWS S3 | Object access logs | Separate S3 bucket (if configured) | Configurable (not enabled by default) | ? | ? | ? |
| GitHub | Webhook delivery logs | GitHub UI | 30 days | Yes | Yes | ? |
| GitHub | Push event metadata | GitHub API | Indefinite | Yes | Yes | Yes |

**Tasks:**

1. Complete the cells marked with `?`. For each, state your answer and the reasoning based on the component's behavior.

2. An incident is discovered 35 days after the suspected compromise date. Based on the table above, which evidence types have definitively expired? Which are at risk of expiring soon?

3. An incident is discovered 4 hours after a suspicious GitHub Actions workflow run. List the evidence collection actions that must be taken within the next 2 hours to prevent evidence loss, ordered by urgency.

---

## Exercise 2 — Evidence Collection Checklist (15 minutes)

You are the first responder on a pipeline security incident. The incident window is: **2024-03-15 14:00 UTC to 2024-03-15 18:00 UTC**. The suspected vector is a compromised GitHub Actions workflow that may have exfiltrated secrets and tampered with a container image.

Produce a time-ordered evidence collection checklist. For each item:
- Identify the evidence type
- Specify the exact location to collect from (API endpoint, S3 bucket path pattern, CLI command)
- Mark whether it must be collected within 2 hours, 24 hours, or 7 days

Use this format:

```
[ ] Priority: IMMEDIATE (< 2 hours)
    Evidence type: GitHub Actions job logs for runs between 14:00–18:00 UTC on 2024-03-15
    Collection method: gh run list --repo org/repo --created 2024-03-15 | grep "2024-03-15 1[4-8]" | xargs -I{} gh run view {} --log > run-{}.log
    Notes: Logs retained 90 days but runner artifacts are already gone; collect logs now to establish job sequence

[ ] Priority: IMMEDIATE (< 2 hours)
    Evidence type: ...
```

Your checklist must include at least 8 items covering all five evidence categories.

---

## Exercise 3 — Evidence Externalization Step (25 minutes)

The single most impactful pipeline forensic readiness improvement for ephemeral runner environments is adding a post-step job that externalizes critical build evidence before the runner terminates. This step runs even if the build fails or is cancelled.

### Part A — Write the Pipeline Step

Write a GitHub Actions job step (or a reusable composite action) that runs as a `post` step (after all other steps, including on failure) and uploads the following to a persistent evidence store (an S3 bucket with Object Lock, configured as in Lab 5):

1. The full job log (stdout/stderr from all prior steps, captured from the GitHub Actions runner log file path)
2. A structured JSON audit event containing:
   - `github.run_id`, `github.run_number`, `github.sha`, `github.ref`, `github.actor`
   - `github.workflow`, `github.job`
   - Job start time and current time (post-step execution time)
   - Exit status of the preceding steps
3. Any files matching `**/attestation.json` or `**/sbom.json` produced during the build

Your step should:
- Use the OIDC-authenticated AWS credential (no static keys)
- Fail silently if the evidence upload fails (do not block deployment for an audit trail upload failure)
- Include the `github.run_id` in the S3 object key path for easy retrieval

### Part B — Evaluate the Limitations

Your externalization step above is a significant improvement over no externalization, but it has limitations.

Answer the following:

1. What evidence categories does this step still fail to capture? (Hint: think about process-level activity, network connections made by the build, and environment variable values)

2. The step uses `fail silently` semantics for the upload. Is this the right security/availability trade-off? Under what circumstances should an evidence upload failure block the build?

3. If a sophisticated attacker compromises the pipeline runner before the post-step runs, what could they do to prevent the evidence from being uploaded, and how would you detect this?

---

## Summary

Pipeline evidence collection is not a passive activity. Evidence expires, evidence requires deliberate configuration to produce, and some evidence categories require upfront infrastructure investment to make available at all.

The evidence inventory from Exercise 1 establishes what is and is not available by default. The checklist from Exercise 2 operationalizes that inventory into a response procedure. The externalization step from Exercise 3 closes the most critical gap — ephemeral runner evidence — in a way that survives runner termination.

Chapters 7 and 8 extend this evidence taxonomy to cloud/container environments and supply chain artifacts respectively.

---

## Further Reading

- Chapter 5 (in the book): Immutable Audit Trails — the S3 Object Lock bucket used in Exercise 3
- Chapter 7: Cloud and Container Forensic Artifacts — IAM and ECS evidence sources
- GitHub documentation: [Workflow run logs API](https://docs.github.com/en/rest/actions/workflow-runs)
- AWS documentation: [CloudTrail log file format](https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-log-file-format.html)
