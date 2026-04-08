# Chapter 11 — Supply Chain Attack Investigation

## What You Will Learn

This chapter covers the investigation of software supply chain attacks — incidents in which an attacker compromises an artifact that enters the organization's pipeline from an external source. You will learn to identify the indicators of supply chain compromise, trace the ingestion of a malicious artifact through the pipeline, determine the blast radius of downstream usage, and produce the artifact disposition and notification recommendations required for response.

## Why This Matters

Supply chain attacks are structurally different from direct intrusions. The attacker does not need to penetrate the organization's defenses; they need only compromise a dependency, action, base image, or tool that the organization's pipeline trusts and ingests automatically. Once the malicious artifact enters the pipeline, it executes with the permissions granted to that artifact class — which can be substantial.

Investigation is complicated by the same opacity that makes supply chain attacks effective. The organization may not know exactly which versions of which dependencies were in use at any given time, which pipeline jobs ingested a specific artifact, or which production systems were reached by artifacts built with the compromised component. Reconstructing this information from pipeline evidence is the core challenge this chapter addresses.

## Investigation Framework

Supply chain attack investigations require answering four questions in order:

**Q1 — What artifact was compromised, and when?** Identify the specific artifact (package version, action SHA, image digest, tool binary) that was malicious, and the time window during which the malicious version was available. This establishes the investigation scope.

**Q2 — Which pipeline executions ingested the malicious artifact?** Correlate artifact ingestion records (lockfile states, dependency resolution logs, image pull records) against the compromise window to identify every pipeline execution that may have used the malicious artifact.

**Q3 — What did the malicious artifact do?** Where possible, analyze the malicious artifact's behavior (static analysis, sandbox execution, runtime behavior logs) to understand what actions it took when it executed in the pipeline.

**Q4 — What is the downstream blast radius?** Trace every artifact produced by a pipeline execution that ingested the malicious artifact. Identify which of those artifacts reached production, test, or staging environments, and which users or systems may have been exposed to their effects.

## Key Evidence Sources

- Lockfiles committed to version control (package-lock.json, go.sum, Pipfile.lock) — establish which exact artifact versions were resolved at each pipeline execution
- Pipeline job logs — artifact download receipts, dependency resolution output, action execution logs
- SBOM records — if generated, provide a structured record of all components in each build artifact
- Registry and CDN access logs — confirm which artifact versions were fetched and when
- Rekor/Sigstore transparency logs — for signed artifacts, confirm whether a malicious artifact was signed with the expected key

## What You Will Practice

This chapter's lab uses a simulated xz-utils style scenario: a widely-used library was backdoored for a 14-day window, and the organization's pipelines were running builds during that window. You will:

- Determine which pipeline executions ingested the affected library version using lockfile and dependency log evidence
- Identify which build artifacts are potentially contaminated
- Use SBOM records to trace contaminated artifacts to deployment targets
- Produce an artifact quarantine list and a draft external notification

## Lab

See [lab/README.md](lab/README.md) for the guided supply chain attack investigation exercise.
