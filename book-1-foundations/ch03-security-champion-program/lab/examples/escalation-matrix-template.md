# Security Champion Escalation Matrix — [Organization Name]

This matrix defines the escalation path for common security findings. Its purpose is to ensure
consistency in how security champions respond to findings — avoiding both under-escalation
(handling a critical finding independently) and over-escalation (escalating every low-severity
dependency advisory to the security team).

---

## Escalation Tiers

| Tier | Action | Criteria |
|------|--------|----------|
| **Tier 1 — Handle independently** | Champion triages, creates ticket, owns remediation | Low/Medium severity, no known exploit, not in critical path |
| **Tier 2 — Notify security team** | Champion notifies security Slack channel, creates ticket with context | High severity, uncertain exploitability, or affects sensitive data |
| **Tier 3 — Escalate immediately** | Champion pages security on-call and notifies their manager | Critical severity, active exploit available, or potential active compromise |

---

## Finding Escalation Reference

| Finding Type | Tier | Rationale |
|-------------|------|-----------|
| Dependency with CVSS < 7.0, no known exploit | Tier 1 | Low risk, standard remediation workflow |
| Dependency with CVSS 7.0–8.9, no known exploit | Tier 1–2 | Contextual — depends on whether dependency is in a network-exposed path |
| Dependency with CVSS ≥ 9.0, active exploit | Tier 3 | Critical — remediate or mitigate within 24 hours |
| Hardcoded secret in a feature branch (not merged) | Tier 2 | Secret must be rotated immediately even if branch is unmerged |
| Hardcoded secret in main branch (deployed) | Tier 3 | Treat as active exposure — rotate immediately, audit access logs |
| Authentication bypass (non-production endpoint) | Tier 2 | Confirm blast radius before classifying; may be Tier 3 |
| Authentication bypass (production, PII/financial data) | Tier 3 | Critical — potential active exploitation |
| SQL injection (read-only query, no PII) | Tier 1–2 | Remediate in current sprint; not an emergency |
| SQL injection (write endpoint with PII) | Tier 3 | Critical — data integrity and confidentiality at risk |
| Suspected active compromise (unusual process, lateral movement) | Tier 3 | Immediate incident response activation |

---

## Escalation Contact Information

| Tier | Contact Method | Response Expectation |
|------|---------------|---------------------|
| Tier 1 | Create ticket in [security backlog board] | Acknowledged within [X] business days |
| Tier 2 | Post in [#security-champions Slack] + create ticket | Security team response within [X] hours during business hours |
| Tier 3 | Page [security on-call via PagerDuty/OpsGenie] + notify manager | Immediate response (SLA: [X] minutes) |

---

## Escalation Context Requirements

When escalating, include:

1. **Finding description** — What was found, where (service/repo/endpoint), and how it was discovered
2. **Blast radius assessment** — What data, services, or users could be affected
3. **Current exposure** — Is this in production? Is it internet-facing? When was it deployed?
4. **Initial remediation thoughts** — What you believe the fix is, even if approximate
5. **Business context** — Any upcoming releases, compliance deadlines, or customer commitments relevant to the finding
