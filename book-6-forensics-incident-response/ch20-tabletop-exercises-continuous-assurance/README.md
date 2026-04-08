# Chapter 20 — Tabletop Exercises and Continuous Forensic Assurance

## What You Will Learn

This chapter covers how to design, run, and learn from tabletop exercises that test pipeline forensic response capabilities — and how to build a continuous assurance program that validates forensic readiness on an ongoing basis rather than only during incidents. You will learn the exercise formats that produce realistic IR skill development, the metrics that measure forensic readiness over time, and the feedback loop that drives improvement between exercises.

## Why This Matters

Forensic readiness controls that have never been exercised are of unknown value when an incident occurs. Organizations that test their forensic response procedures before they need them consistently outperform those that do not. The difference is not primarily in the quality of their tools or the sophistication of their evidence architecture — it is in the practiced skill of the responders who know where evidence lives, how to collect it, and how to correlate it under time pressure.

Tabletop exercises are the most cost-effective mechanism for developing and validating that skill. They surface gaps in runbooks, identify evidence sources that are missing or inaccessible, reveal communication and escalation failures, and build shared mental models across the security, engineering, and legal teams that must collaborate during a real incident.

## Exercise Formats

**Format 1 — Injects-based discussion exercise:** A facilitator presents a scenario in stages ("injects") and asks participants how they would respond. No actual systems are involved. Good for testing decision-making, escalation paths, and communication. Low cost; appropriate for quarterly cadence.

**Format 2 — Evidence review exercise:** Participants are given a pre-built set of evidence artifacts (logs, audit records, SBOMs) from a simulated incident and must investigate without facilitator guidance. Good for testing forensic analysis skills and runbook completeness. Medium cost; appropriate for semi-annual cadence.

**Format 3 — Red team / purple team exercise:** A red team executes a realistic pipeline attack scenario against a test environment while the security team responds in real time. The highest fidelity format; surfaces gaps that tabletop formats miss. High cost; appropriate for annual cadence or after major architecture changes.

## Continuous Assurance Metrics

Forensic readiness is a property that degrades as pipelines evolve. New pipeline components may not emit the required evidence categories. Log retention policies may be changed by infrastructure changes. New machine identities may not have correct audit logging enabled.

Continuous assurance metrics track forensic readiness properties automatically:

- **Evidence completeness rate:** Percentage of pipeline components emitting all five evidence categories
- **Retention compliance rate:** Percentage of evidence sources meeting the required retention duration
- **Correlation coverage:** Percentage of pipeline executions for which a complete correlated event timeline can be reconstructed
- **Runbook currency:** Age of the most recent validated incident response runbook for each pipeline component class

## What You Will Practice

This chapter's lab has two components:

**Exercise 1** — Run a 60-minute injects-based tabletop exercise using the provided scenario script (a supply chain compromise discovered 72 hours after the incident began). Participants receive role assignments and respond to five sequential injects. The lab provides a debrief guide for identifying gaps.

**Exercise 2** — Design a continuous assurance dashboard for a reference pipeline environment. Given the five FRS dimensions from Chapter 3 and the evidence sources cataloged in Chapters 5–8, specify the automated checks that would track each dimension over time and the alerting thresholds that would trigger a forensic readiness review.

## Lab

See [lab/README.md](lab/README.md) for the tabletop exercise script and continuous assurance design exercise.
