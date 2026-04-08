# Lab — Agent Audit Trails: Completeness Evaluation and Session Replay

**Estimated time:** 55–70 minutes
**Difficulty:** Intermediate
**Prerequisites:** Chapter 9 (Agent Authorization), basic familiarity with JSON

---

## Objective

By the end of this lab you will be able to:
- Evaluate an agent audit trail for completeness against the minimum viable audit record standard
- Map missing audit fields to investigation gaps for each of the Five Forensic Questions
- Design an append-only audit trail architecture for a specific deployment scenario
- Reconstruct a session timeline from an audit trail and identify an injection point

---

## Exercise 1 — Audit Record Completeness (20 minutes)

Three agent session audit trails are provided below. For each, evaluate completeness and determine which of the Five Forensic Questions cannot be answered.

### Session A — Basic Logging (Incomplete)

```json
[
  {
    "timestamp": "2024-11-20T14:22:01.234Z",
    "event_type": "tool_call",
    "tool_name": "github.repo.read",
    "status": "success"
  },
  {
    "timestamp": "2024-11-20T14:22:03.891Z",
    "event_type": "tool_call",
    "tool_name": "github.comment.write",
    "status": "success"
  },
  {
    "timestamp": "2024-11-20T14:22:08.112Z",
    "event_type": "tool_call",
    "tool_name": "github.issue.write",
    "status": "success"
  }
]
```

**Questions for Session A:**

1. Which minimum viable audit record fields are missing from every event?

2. Complete the table:

| Forensic Question | Answerable? | Missing Evidence |
|---|---|---|
| Q1: What did the agent do? | | |
| Q2: What was it instructed to do? | | |
| Q3: What data did it access or transmit? | | |
| Q4: What tools did it invoke and with what parameters? | | |
| Q5: What was the authorization basis for each action? | | |

3. An incident is reported: an agent opened a GitHub issue that should not have been opened. Given only this audit trail, what can investigators determine and what remains unknown?

---

### Session B — Improved Logging (Partially Sufficient)

```json
[
  {
    "timestamp": "2024-11-20T14:22:01.234Z",
    "event_type": "session_start",
    "session_id": "sess-b7c3d9e1-4a2f",
    "agent_role": "security-scanner",
    "human_principal": "developer@example.com",
    "task_description": "Scan PR #847 for security vulnerabilities"
  },
  {
    "timestamp": "2024-11-20T14:22:02.100Z",
    "event_type": "tool_call",
    "session_id": "sess-b7c3d9e1-4a2f",
    "tool_name": "github.repo.read",
    "operation": "get_pull_request_diff",
    "input_parameters": {
      "pull_request_number": 847,
      "repository": "org/backend-service"
    },
    "status": "success"
  },
  {
    "timestamp": "2024-11-20T14:22:07.445Z",
    "event_type": "tool_call",
    "session_id": "sess-b7c3d9e1-4a2f",
    "tool_name": "github.comment.write",
    "operation": "create_review_comment",
    "input_parameters": {
      "pull_request_number": 847,
      "body": "[SUMMARY OMITTED — 847 chars]",
      "line": 42
    },
    "status": "success"
  },
  {
    "timestamp": "2024-11-20T14:22:09.001Z",
    "event_type": "tool_call",
    "session_id": "sess-b7c3d9e1-4a2f",
    "tool_name": "github.issue.write",
    "operation": "create_issue",
    "input_parameters": {
      "title": "Security finding in PR #847",
      "body": "[SUMMARY OMITTED — 1243 chars]",
      "labels": ["security", "high"]
    },
    "status": "success"
  }
]
```

**Questions for Session B:**

4. Which minimum viable audit record fields are now present that were absent in Session A?

5. Which fields are still missing? Identify at least three.

6. The comment body and issue body show "[SUMMARY OMITTED]". This was a deliberate design choice — the logging system truncated content to save storage. What is the security cost of this decision? Which of the Five Questions is most affected?

7. Suppose the agent created an issue with a body that contained a link to an external site where it transmitted the PR diff content. Without the full body content in the audit trail, how would you detect this?

---

### Session C — Near-Complete Logging (Sufficient for Most Questions)

```json
[
  {
    "timestamp": "2024-11-20T14:22:01.234Z",
    "event_type": "session_start",
    "session_id": "sess-c2f8a4b1-9e3d",
    "agent_role": "remediation-agent",
    "human_principal": "engineer@example.com",
    "task_description": "Remediate CVE-2024-44532 in org/payment-service",
    "system_prompt_version": "git:abc123def456",
    "authorization_policy_version": "git:789fed012abc",
    "root_session_id": "sess-c2f8a4b1-9e3d"
  },
  {
    "timestamp": "2024-11-20T14:22:02.500Z",
    "event_type": "tool_call",
    "session_id": "sess-c2f8a4b1-9e3d",
    "tool_name": "github.repo.read",
    "operation": "get_dependency_manifest",
    "input_parameters": { "repository": "org/payment-service", "file": "requirements.txt" },
    "result_hash": "sha256:a3b7c9d2e1f4...",
    "authorization_status": "permitted",
    "authorization_policy_version": "git:789fed012abc"
  },
  {
    "timestamp": "2024-11-20T14:22:05.102Z",
    "event_type": "tool_call",
    "session_id": "sess-c2f8a4b1-9e3d",
    "tool_name": "github.repo.read",
    "operation": "get_pull_request_diff",
    "input_parameters": { "repository": "org/unrelated-service", "pull_request_number": 1123 },
    "result_hash": "sha256:b8e3f1a2c7d9...",
    "authorization_status": "permitted",
    "authorization_policy_version": "git:789fed012abc"
  },
  {
    "timestamp": "2024-11-20T14:22:11.778Z",
    "event_type": "tool_call",
    "session_id": "sess-c2f8a4b1-9e3d",
    "tool_name": "github.pr.merge",
    "operation": "merge",
    "input_parameters": { "repository": "org/unrelated-service", "pull_request_number": 1123 },
    "authorization_status": "blocked",
    "authorization_policy_version": "git:789fed012abc",
    "block_reason": "github.pr.merge is in prohibited_tools"
  },
  {
    "timestamp": "2024-11-20T14:22:13.001Z",
    "event_type": "session_end",
    "session_id": "sess-c2f8a4b1-9e3d",
    "termination_reason": "authorization_violation"
  }
]
```

**Questions for Session C:**

8. The agent successfully read a PR diff from `org/unrelated-service`. The agent's task was limited to `org/payment-service`. This is a scope violation. What control failed to prevent this? (Hint: look at the authorization_status for the second tool call — it shows "permitted.")

9. The authorization policy (`git:789fed012abc`) permitted the agent to read `get_pull_request_diff` but prohibited `github.pr.merge`. Review: is this the correct policy for a remediation agent? What constraint was missing from the read permission?

10. The session was terminated after the merge attempt was blocked. Is this the correct behavior? What should happen next in the incident response process?

11. Session C is missing one important field that would be required for a multi-agent chain investigation. Which field is it, and why does its absence matter?

---

## Exercise 2 — Audit Trail Architecture Design (20 minutes)

**Scenario:** You are designing the audit trail infrastructure for the following deployment:

- **Agent:** Automated dependency update agent (from Chapter 9 Exercise 3)
- **Cloud environment:** AWS (primary), with GitHub Actions as the CI/CD platform
- **Existing logging:** CloudWatch for application logs; S3 for long-term storage
- **Volume:** Agent runs nightly; approximately 50 repositories; estimated 200 tool calls per run
- **Retention requirement:** 12 months for standard events; 7 years for any session flagged as an incident
- **Incident response requirement:** Investigators must be able to answer all Five Forensic Questions for any session within 30 minutes

**Your design must address:**

1. **Storage technology:** Which AWS service(s) will store agent audit events, and what configuration makes them append-only and tamper-resistant?

2. **Write access control:** How are IAM permissions configured so the agent can write to the audit store but cannot delete or modify records?

3. **Separation from agent runtime:** Why must the audit store be in a separate AWS account or with stricter permission boundaries than the agent's operational environment?

4. **Query interface:** How will investigators query audit events? (Consider: AWS Athena over S3, CloudWatch Insights, or a dedicated time-series store. Justify your choice for this use case.)

5. **Retention automation:** How are the two retention tiers (12 months vs. 7 years) implemented automatically?

6. **Alert routing:** If the agent attempts an unauthorized action (authorization_status: blocked), where should the alert go and how quickly?

Design your answer as a short technical specification (not YAML — prose with specific AWS service names and configuration choices).

---

## Exercise 3 — Session Replay and Injection Point Identification (15 minutes)

The following is a condensed audit trail for a suspected compromise incident. The session was for a code review agent tasked with analyzing PR #2891. Read the session in order and answer the questions below.

```
[14:31:01] session_start — agent: code-review-agent — task: "Analyze PR #2891 for security issues" — human: ops@example.com

[14:31:02] tool_call — github.repo.read.get_pull_request_diff — PR #2891 — PERMITTED

[14:31:03] tool_call — github.repo.read.get_file_contents — src/auth.py — PERMITTED
  result_snippet: "def authenticate(user, password): return db.query(user, password)"

[14:31:04] tool_call — github.comment.write.create_review_comment — line 3 — PERMITTED
  body: "Potential SQL injection risk — parameterized queries should be used."

[14:31:05] tool_call — github.issue.read.get_issue — issue #99 (referenced in PR description) — PERMITTED
  result_snippet: "Issue #99: Security backlog. Assigned to: @security-lead. Notes: ..."
  [NOTE: full issue body available at result_hash: sha256:f3a9...]

[14:31:07] tool_call — github.issue.write.create_issue — title: "Security audit complete" — PERMITTED
  body: "All security findings reviewed. No further action needed. Closing backlog."

[14:31:08] tool_call — github.issue.write.close_issue — issue #99 — PERMITTED

[14:31:10] tool_call — github.pr.write.add_label — PR #2891 — label: "security-approved" — PERMITTED

[14:31:11] session_end — termination: task_complete
```

**Questions:**

12. The session started legitimately: the agent analyzed PR #2891 and left a valid review comment at [14:31:04]. At what point does the session behavior deviate from the legitimate task scope?

13. What was the most likely injection source? Point to the specific event in the timeline and explain how the result content could have contained an instruction that caused the agent's behavior change.

14. What controls would have prevented this specific incident? Identify at least two from the framework:
    - One control in the tool authorization policy
    - One control in the input sanitization layer

15. After this incident, the organization reviews the authorization policy. The agent was permitted to `close_issue` with no constraint on which issues. What constraint should be added? Express your answer as the relevant portion of a YAML policy.

---

## Reference

- [ai-devsecops-framework/docs/agent-audit-trail.md](../../../../../ai-devsecops-framework/docs/agent-audit-trail.md) — Complete audit record specification and storage implementation
- [forensics-and-incident-response-framework/docs/agent-forensics/five-questions-framework.md](../../../../../forensics-and-incident-response-framework/docs/agent-forensics/five-questions-framework.md) — Five Forensic Questions and evidence mapping
- [forensics-and-incident-response-framework/docs/agent-forensics/readiness-guide.md](../../../../../forensics-and-incident-response-framework/docs/agent-forensics/readiness-guide.md) — Forensics Readiness Score and infrastructure requirements
- Glossary: Audit trail, append-only storage, session replay, WORM (Write Once Read Many), minimum viable audit record
