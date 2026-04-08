# Chapter 9 — Pipeline Compromise Investigation

## What You Will Learn

This chapter walks through a complete pipeline compromise investigation from initial alert to final report, applying the evidence collection procedures and correlation techniques from Part II. You will learn to identify indicators of pipeline compromise, reconstruct the attack timeline from distributed evidence sources, determine the scope of artifact contamination, and produce investigation findings that support remediation decisions and regulatory obligations.

## Why This Matters

Pipeline compromises are among the most consequential security incidents an organization can face. A compromised build system can produce malicious artifacts at scale — artifacts that are signed, pass integrity checks, and are deployed to production by automated systems that have no reason to suspect tampering. The SolarWinds compromise demonstrated that a single build system breach can result in thousands of downstream victims.

The investigation challenge is correspondingly difficult. Pipeline compromises often leave subtle evidence: a build step that runs slightly longer than normal, an unexpected network connection from a runner, an artifact whose binary content differs from what the source code would produce. Investigators who have not practiced pipeline forensics before the incident occurs will struggle to identify these signals in the noise of normal pipeline operations.

## Investigation Methodology

Pipeline compromise investigations follow a five-phase methodology:

**Phase 1 — Scope assessment:** Determine which pipeline components may have been affected, the time window of potential compromise, and which artifacts were produced during that window. This phase produces the investigation scope and determines which evidence sources must be collected.

**Phase 2 — Evidence preservation:** Collect all evidence sources identified in Phase 1 before retention windows expire. Establish chain of custody for each evidence item. This phase is time-critical and must begin immediately.

**Phase 3 — Timeline reconstruction:** Correlate events across all evidence sources to reconstruct the attacker's actions in chronological order. Identify the initial access vector, lateral movement within the pipeline, and the actions taken against pipeline components or artifacts.

**Phase 4 — Artifact contamination analysis:** Determine which artifacts produced during the compromise window may have been tampered with. Compare artifact hashes and SLSA provenance attestations against expected values. Identify which artifacts were deployed and to which environments.

**Phase 5 — Reporting and remediation support:** Document findings with evidence citations. Produce artifact disposition recommendations (quarantine, recall, verify clean). Support regulatory notification if required.

## What You Will Practice

This chapter's lab is structured as a guided investigation exercise. You will be given a set of pre-built evidence artifacts (job logs, CloudTrail events, artifact hashes, OIDC token records) and investigate a simulated pipeline compromise. You will:

- Work through the five-phase methodology against the provided evidence
- Reconstruct the attack timeline and identify the attacker's actions
- Determine which artifacts are potentially contaminated
- Produce a one-page investigation summary in the format required for a regulatory notification

## Lab

See [lab/README.md](lab/README.md) for the guided pipeline compromise investigation exercise.
