# Lab 20 — Tabletop Exercise and Continuous Assurance Design

**Estimated time:** 75–90 minutes (Exercise 1 is designed for a group; can be adapted for solo study)
**Difficulty:** Intermediate
**Prerequisites:** Familiarity with the FRS dimensions (Chapter 3); completion of at least two prior labs in this book; optional but recommended: a second participant for the tabletop exercise

---

## Objective

By the end of this lab you will be able to:
- Facilitate or participate in an injects-based pipeline security tabletop exercise
- Identify gaps in incident response procedures revealed by the exercise
- Design a continuous assurance dashboard specification for forensic readiness monitoring
- Translate FRS dimensions into automatable, measurable checks

---

## Exercise 1 — Tabletop Exercise: The Phantom Dependency (45–60 minutes)

### Setup

This exercise is designed for 2–5 participants with assigned roles. In a solo setting, work through each inject by reasoning through all role perspectives before recording your response.

**Roles:**
- **Incident Commander (IC):** Owns the response; makes escalation decisions; manages the timeline
- **Security Engineer:** Handles evidence collection and technical investigation
- **Engineering Lead:** Represents the affected team; answers pipeline and deployment questions
- **Legal/Compliance:** Raises regulatory and notification obligations
- **Communications Lead:** Manages stakeholder communication

**Facilitator note:** Read each inject aloud. Allow 5–8 minutes of discussion per inject before presenting the next one. After the final inject, conduct the debrief.

---

### Scenario Brief

Verdant Software develops a customer data analytics platform deployed on AWS EKS. Their pipeline runs on GitHub Actions and deploys via ArgoCD. It is a Thursday afternoon.

---

### Inject 1 — Initial Alert (5 minutes)

**T+0:00**

Your security monitoring system fires an alert:

> `ALERT [HIGH]: Unusual outbound traffic detected from EKS node pool prod-ng-02. Destination: 178.62.54.196:443. Volume: 47 MB over 12 minutes. Traffic pattern is consistent with data exfiltration.`

**Discussion questions:**
1. What is the IC's first action?
2. What information does the Security Engineer need before beginning investigation?
3. Does the Engineering Lead know what is running on prod-ng-02 right now?
4. Is there any reason to begin notifying Legal/Compliance at this stage?

**Record:** Your team's immediate actions and any decisions made.

---

### Inject 2 — First Evidence (8 minutes)

**T+0:15**

The Security Engineer reports:

> "I've pulled the Kubernetes audit log for the last 2 hours. The outbound traffic is coming from pods running the `verdant-analytics-api:v4.2.1` image. I see that image was deployed 3 hours ago via a GitOps commit. The commit updated a dependency: `data-transform-utils` from version 1.9.2 to 2.0.1. I checked the npm registry — 2.0.1 was published 5 days ago by an account that was registered 6 days ago."

**Discussion questions:**
1. Is this enough evidence to confirm a supply chain attack? What is still unknown?
2. Should the pods running `v4.2.1` be terminated immediately? What are the trade-offs?
3. What additional evidence must be collected before any pods are terminated?
4. Has any customer data been exfiltrated? What would help you answer that question?

**Record:** Decisions and rationale.

---

### Inject 3 — Scope Expands (8 minutes)

**T+0:35**

The Engineering Lead reports:

> "We deploy to three environments: staging, production-us, and production-eu. I just checked — `verdant-analytics-api:v4.2.1` is running in all three. The image was built 5 days ago and deployed to staging 5 days ago, production-us 3 hours ago, and production-eu 2 hours ago."

Legal/Compliance asks: "Do any of these environments process EU personal data?"

Engineering Lead: "Production-eu processes data for our European customers under a DPA with a 72-hour breach notification obligation."

**Discussion questions:**
1. The IC must now decide whether to treat this as a confirmed breach. What threshold is the IC using?
2. What is the exact start of the notification clock if this is a confirmed breach, and what does the 72-hour window mean for your response timeline?
3. Should the production-eu environment be isolated immediately? Who makes that call?
4. What evidence must be preserved before any environment is taken offline?

**Record:** Breach determination decision and reasoning. Start time if clock is running.

---

### Inject 4 — Evidence Gap (8 minutes)

**T+1:00**

The Security Engineer reports:

> "I'm trying to determine exactly what data was exfiltrated. The EKS nodes don't have VPC flow logs enabled. The S3 access logs for the customer data bucket have a 30-day retention policy — but the malicious package has been in staging for 5 days. I can see the outbound traffic volume (47 MB from production-us in the last 12 minutes) but I have no record of what specific data was accessed."

**Discussion questions:**
1. Can the organization make a breach notification without knowing exactly what data was exfiltrated? What is the legal standard?
2. What is the IC's position on the 72-hour notification clock given this evidence gap?
3. What forensic readiness controls would have closed this gap?
4. Going forward, what are the two highest-priority forensic readiness investments the Security Engineer should propose?

**Record:** Notification decision and the forensic readiness gaps identified.

---

### Inject 5 — Remediation Decision (8 minutes)

**T+1:30**

The Security Engineer has:
- Confirmed the malicious package via static analysis
- Identified a clean version (`1.9.2`) to revert to
- Confirmed the malicious package was NOT present in any image before `v4.2.1`
- Revoked the IAM task role used by the affected pods and rotated the credentials

The Engineering Lead asks: "We have a clean build ready (`v4.2.2`) that reverts to `data-transform-utils@1.9.2`. Should we deploy it immediately to stop the bleeding, or wait until we have more information?"

**Discussion questions:**
1. What is the risk of deploying immediately versus waiting?
2. What evidence must be collected from the running compromised pods before they are replaced?
3. After the clean deployment, what validation steps confirm the malicious package is no longer running?
4. What must be in place before the IC declares the incident contained?

**Record:** Deployment decision and validation plan.

---

### Debrief (15 minutes)

Work through the following debrief questions as a group (or solo):

1. **Runbook gaps:** At which inject did your team lack a documented procedure? What runbook would have helped?

2. **Evidence gaps:** At which inject was the investigation blocked by missing evidence? Which FRS dimension does each gap correspond to?

3. **Decision quality:** Looking back, which decisions were made with insufficient information? Which decisions were made correctly under uncertainty?

4. **Notification timing:** If this incident occurred in a real organization, would the 72-hour notification obligation have been met? What would have needed to be different?

5. **Two improvements:** What are the two highest-priority changes your organization would make after this exercise?

---

## Exercise 2 — Continuous Assurance Dashboard Design (20 minutes)

### Background

Continuous assurance means measuring forensic readiness automatically and continuously — not just during exercises or after incidents. The FRS dimensions from Chapter 3 provide the framework; this exercise produces the specification for automating those measurements.

### Part A — Define Automated Checks

For each FRS dimension, define at least one automated check that can be run on a schedule (e.g., daily) against a real pipeline environment. For each check, specify:

| Dimension | Check Name | What It Measures | Data Source | Pass Criteria | Alert Threshold |
|-----------|------------|-----------------|------------|---------------|----------------|
| Evidence Completeness | SBOM coverage check | % of production builds with a generated SBOM | CI/CD job metadata API | 100% of production builds | < 95% over rolling 7 days |
| Tamper Resistance | ... | ... | ... | ... | ... |
| Retention and Availability | ... | ... | ... | ... | ... |
| Correlation Capability | ... | ... | ... | ... | ... |
| Tested Response Procedures | ... | ... | ... | ... | ... |

Complete the table with at least one check per dimension (two or more is better).

### Part B — Degradation Detection

Forensic readiness properties degrade as pipelines evolve. New components are added without being onboarded to evidence collection. Retention policies are changed. New machine identities are created without audit logging.

Design a degradation detection check for one of the following:

**Option 1:** A check that detects when a new GitHub Actions workflow is added that does not include the evidence externalization step from Lab 6.

**Option 2:** A check that detects when a new AWS IAM role is created without CloudTrail logging enabled for that role's actions.

**Option 3:** A check that detects when the retention policy on a critical evidence store (S3 audit bucket, CloudTrail, Kubernetes audit log) is reduced below the required minimum.

For your chosen option, specify:
- Trigger: What event or state change triggers the check?
- Detection method: How is the violation detected (API call, config scan, event rule)?
- Alert: Who is notified and with what urgency?
- Remediation: What is the expected response action?

---

## Summary

Tabletop exercises and continuous assurance are the operational disciplines that keep forensic readiness from degrading. Exercises reveal the gaps between documented procedures and actual response capability. Continuous assurance catches the incremental drift that makes those gaps grow undetected.

The Phantom Dependency scenario illustrated how quickly a well-prepared team can hit evidence walls when forensic readiness controls are missing — and how those walls directly affect the ability to make defensible breach notification decisions under a regulatory clock.

The continuous assurance dashboard connects the FRS assessment (a point-in-time measurement) to an ongoing monitoring program that catches readiness regressions before the next incident.

---

## Further Reading

- Chapter 3 (in the book): Forensics Readiness Score — the dimensions measured by the continuous assurance dashboard
- Chapter 19: Legal Hold, eDiscovery, and Reporting — the regulatory obligations that drive notification timing in Inject 3
- [NIST SP 800-84](https://csrc.nist.gov/publications/detail/sp/800-84/final) — Guide to Test, Training, and Exercise Programs for IT Plans and Capabilities
- [GDPR Article 33](https://gdpr-info.eu/art-33-gdpr/) — 72-hour breach notification obligation referenced in Inject 3
