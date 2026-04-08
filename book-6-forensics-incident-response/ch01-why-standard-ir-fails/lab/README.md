# Lab 1 — Standard IR Failure Analysis

**Estimated time:** 45–60 minutes
**Difficulty:** Beginner–Intermediate
**Prerequisites:** Familiarity with basic incident response concepts; awareness of CI/CD pipeline components (version control, build runners, artifact registries, deployment systems)

---

## Objective

By the end of this lab you will be able to:
- Identify the five structural gaps between standard IR and pipeline forensics
- Map specific IR failures in a case scenario to the gap that caused them
- Propose minimal forensic readiness controls that would have prevented each failure
- Prioritize those controls by impact and implementation cost

---

## Background: The Northgate Incident

The scenario below is a composite based on patterns observed in real pipeline compromise investigations. The organization name and details are fictional.

**Scenario:** Northgate Financial Services operates a cloud-native application built and deployed via GitHub Actions. On a Tuesday afternoon, their security operations center received an alert from their CSPM indicating that an IAM role used by their CI/CD pipeline had called `s3:GetObject` on a bucket containing customer PII — an action outside the role's normal usage pattern.

The security team initiated an incident response. The following events occurred over the next 72 hours:

**Hour 0–4 (Initial response):** The team identified the IAM role involved and attempted to determine which pipeline job had triggered the anomalous API call. GitHub Actions logs for the relevant workflow showed the job had run, but the runner had already been recycled. No process-level artifacts were available from the runner.

**Hour 4–12 (Timeline reconstruction):** The team attempted to reconstruct the pipeline execution timeline. GitHub Actions provides job-level timestamps but does not correlate to CloudTrail request IDs. The team could not definitively match the anomalous S3 call to a specific job execution.

**Hour 12–24 (Artifact analysis):** The team wanted to determine whether artifacts produced during the suspect window had been tampered with. The pipeline did not generate SLSA provenance attestations or SBOMs. Artifact digests were available in the registry but there were no records of what the expected digest should have been prior to the incident.

**Hour 24–48 (Supply chain check):** The team attempted to determine whether any third-party GitHub Actions used in the workflow were compromised. The workflow referenced actions by mutable tag (`uses: actions/checkout@v4`) rather than pinned digest. The team could not determine with certainty which version of the action had executed during the suspect window.

**Hour 48–72 (Scope determination):** The team could not definitively determine whether customer PII had been exfiltrated, because the S3 access logs had been retained for only 30 days, and the suspicious activity pattern had begun 35 days before the alert was triggered.

---

## Exercise 1 — Gap Identification (20 minutes)

For each IR failure described above, identify which of the five structural gaps (from Chapter 1) is the primary cause. A single failure may involve multiple gaps — identify the primary one and note any secondary gaps.

| IR Failure | Primary Gap | Secondary Gap (if any) | Evidence That Would Have Helped |
|------------|-------------|------------------------|--------------------------------|
| Runner recycled; no process artifacts available | | | |
| Cannot correlate CloudTrail request to specific job | | | |
| No expected artifact digest baseline | | | |
| Action version used during incident is unknown | | | |
| S3 access logs expired before investigation began | | | |

**Reference — the five structural gaps:**
1. Ephemeral compute
2. Distributed event correlation
3. Supply chain opacity
4. Non-human identity proliferation
5. AI component non-determinism

---

## Exercise 2 — Control Mapping (20 minutes)

For each gap you identified in Exercise 1, propose the specific forensic readiness control that would have prevented the IR failure. Use the format below.

**Example:**
- Gap: Ephemeral compute
- Failure prevented: Runner recycled before process artifacts collected
- Control: Export runner process audit log (auditd or eBPF-based) to external append-only store as part of the job post-step
- Implementation effort: Medium (requires post-step configuration in all workflows)
- Chapter that covers this control: Chapter 5 (Immutable Audit Trails), Chapter 6 (Pipeline Forensic Evidence)

Complete the same analysis for the remaining four gaps from Exercise 1.

---

## Exercise 3 — Prioritization (15 minutes)

You have five controls to recommend to the Northgate engineering team. They have capacity to implement two controls in the next sprint and must defer the others.

Using the following criteria, rank the five controls from Exercise 2 and justify your top-two selection:

**Criteria:**
- **Blast radius of the gap:** How severe is the IR failure when this gap is not closed?
- **Frequency of relevance:** How often does this type of gap affect investigations in cloud-native pipeline environments?
- **Implementation effort:** How much engineering work is required to close the gap?
- **Time sensitivity:** Does the evidence lost due to this gap expire quickly, making early investment more valuable?

| Rank | Control | Justification |
|------|---------|---------------|
| 1 | | |
| 2 | | |
| 3 | | |
| 4 | | |
| 5 | | |

---

## Summary

Standard IR methodology fails in pipeline environments because it was designed for evidence that persists: disk images, memory dumps, durable endpoint logs. Pipeline forensics requires evidence that must be deliberately externalized before it vanishes.

The five structural gaps are not abstract categories — each one maps to a specific type of investigation failure that occurs when organizations apply standard IR to pipeline incidents. Closing the gaps requires upfront investment in forensic readiness controls. The cost of that investment is predictable; the cost of an investigation that fails for lack of evidence is not.

---

## Further Reading

- Chapter 3 (in the book): Forensics Readiness Score — scoring your organization's evidence coverage across all five gaps
- Chapter 5: Immutable Audit Trails — closing the ephemeral compute gap
- Chapter 6: Pipeline Forensic Evidence — closing the distributed correlation and supply chain opacity gaps
