# Chapter 3 — The Forensics Readiness Score

## What You Will Learn

This chapter introduces the Forensics Readiness Score (FRS) — a structured, measurable assessment of an organization's ability to collect, preserve, and produce pipeline forensic evidence. You will learn the five scoring dimensions, how to evaluate each dimension against observable controls, and how to produce a scored assessment that identifies the highest-priority readiness gaps for remediation.

## Why This Matters

Forensic readiness is not binary. Organizations exist on a spectrum from having no durable pipeline evidence at all to having signed, tamper-evident, centralized evidence with tested chain-of-custody procedures. Understanding where your organization sits on that spectrum — before an incident occurs — determines what you can and cannot investigate when something goes wrong.

The FRS provides a shared vocabulary for communicating readiness gaps to engineering, security, and leadership stakeholders. A score of 2/5 on Evidence Completeness means something specific: it identifies which evidence categories are missing and what must be built to close the gap. This is more actionable than "we need better logging."

## The Five FRS Dimensions

**Dimension 1 — Evidence Completeness (EC):** Does the organization collect all five pipeline evidence categories — build provenance, artifact integrity, deployment records, identity/authorization events, and runtime behavior — from all pipeline components?

**Dimension 2 — Tamper Resistance (TR):** Is collected evidence written to append-only, externally signed, or otherwise tamper-resistant storage? Can the organization demonstrate that evidence has not been altered between collection and presentation?

**Dimension 3 — Retention and Availability (RA):** Is evidence retained for a duration that covers realistic investigation timelines and regulatory obligations? Can evidence be retrieved within an operational timeframe when an investigation begins?

**Dimension 4 — Correlation Capability (CC):** Can the organization correlate events across pipeline systems using a shared identifier? Is there a mechanism to reconstruct the complete event sequence for a given build, deployment, or agent session?

**Dimension 5 — Tested Response Procedures (TP):** Has the organization exercised its forensic collection and chain-of-custody procedures against realistic incident scenarios? Are response runbooks documented and current?

## Scoring

Each dimension is scored 0–2:
- **0** — No control present; evidence category unavailable or untested
- **1** — Partial control; significant gaps that would impede investigation
- **2** — Full control; evidence complete, durable, and accessible within tested procedures

Maximum FRS: 10. Minimum viable forensic readiness for regulated environments: 7.

## What You Will Practice

This chapter's lab walks through a complete FRS assessment of a reference pipeline environment. You will:

- Review pipeline configuration artifacts and identify which evidence categories are and are not being collected
- Score each FRS dimension with written justification
- Produce a prioritized gap remediation plan with chapter references for each remediation

## Lab

See [lab/README.md](lab/README.md) for the hands-on FRS assessment exercise.
