# Chapter 6 — Pipeline Forensic Evidence

## What You Will Learn

This chapter catalogs the specific evidence types produced by pipeline systems, explains where each type is generated and how long it typically persists, and provides collection procedures for each type. You will learn to distinguish between evidence that is available by default, evidence that requires deliberate configuration to capture, and evidence that cannot be recovered once an ephemeral component terminates.

## Why This Matters

During an investigation, time matters. An investigator who does not know which evidence types exist, where they are stored, and how quickly they expire will spend the first hours of a response discovering the evidence landscape — hours during which ephemeral evidence is being destroyed by normal pipeline operations.

This chapter is designed to be used as a field reference. Every evidence type is described with enough detail to enable an investigator to locate it quickly, assess its completeness, and initiate preservation before it expires.

## Pipeline Evidence Taxonomy

**Category 1 — Source control events:** Commit metadata, push events, pull request activity, branch protection override events, force-push records, webhook delivery logs. Typical retention: 90 days (GitHub), configurable. Key forensic value: establishes the sequence of code changes and identifies the identity that authorized each change.

**Category 2 — Build system records:** Job logs, step output, environment variable names (not values), artifact upload records, build trigger metadata, runner identity and version. Typical retention: 30–90 days, then archived or purged. Key forensic value: establishes what ran during the build and what artifacts were produced.

**Category 3 — Artifact provenance:** SBOM, SLSA provenance attestations, artifact digests, signing certificates, registry upload metadata. Retention: as long as the artifact is retained, or longer if provenance is stored separately. Key forensic value: establishes the chain of custody for artifacts from build to deployment.

**Category 4 — Deployment records:** Deployment trigger events, configuration applied, target environment, rollout status, approval records (who approved what and when). Retention: varies by deployment system; often 30–90 days in deployment tools, longer in cloud provider audit logs. Key forensic value: establishes what artifact version reached which environment and who authorized it.

**Category 5 — Identity and authorization events:** OIDC token issuance records, IAM role assumption events, API key usage logs, service account activity. Location: cloud provider audit logs (CloudTrail, Cloud Audit Logs, Azure Activity Log). Retention: configurable, default often 90 days. Key forensic value: establishes which machine identity took which action in the cloud environment.

## What You Will Practice

This chapter's lab has investigators work against a realistic pipeline evidence inventory. You will:

- Given a list of pipeline systems and their log retention configurations, identify the evidence that will be available 72 hours, 7 days, and 30 days after an incident
- Produce an evidence collection checklist ordered by expiry urgency
- Write a pipeline job step that externalizes build evidence to persistent storage before the runner terminates

## Lab

See [lab/README.md](lab/README.md) for the hands-on pipeline evidence collection exercises.
