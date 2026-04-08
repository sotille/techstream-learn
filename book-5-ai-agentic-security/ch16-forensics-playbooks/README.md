# Chapter 16 — Agent Forensics Investigation Playbooks

## What You Will Learn

This chapter provides structured investigation playbooks for the four highest-frequency agent incident types. You will learn to execute each playbook step-by-step, adapt playbook steps to organizational tool stacks and log availability, and produce investigation reports suitable for executive, technical, and legal audiences. The playbooks apply the Five Forensic Questions framework from Chapter 15 to specific incident scenarios.

## Why This Matters

The Five Forensic Questions provide the investigation framework; playbooks operationalize it. Without playbooks, investigators repeat the evidence-collection and scope-determination work from scratch at every incident. Under time pressure, this leads to incomplete investigations, missed evidence, and inconsistent findings.

Each playbook in this chapter maps to a real incident pattern documented in the field. The playbooks are designed to be executed with imperfect evidence — each step includes a gap path for when expected evidence is unavailable.

## Playbook AF-01 — Unauthorized Tool Call

**Trigger:** An agent's audit log shows a tool call not present in the agent's authorization policy, or a tool call with parameters that exceed authorized scope (e.g., reading a path outside the authorized prefix, posting to an unauthorized URL).

**Severity classification:** High if the unauthorized action affected sensitive data or external systems; Critical if the unauthorized action involved secret access or external exfiltration.

### Investigation Steps

**Step 1 — Establish the tool call record (Q4)**
Retrieve the complete tool call log for the session. For each tool call, record: timestamp, tool name, full input parameters, result disposition. If the audit log does not include full parameters, proceed to step 1a.

Step 1a (gap path): If parameters are absent, retrieve tool execution logs from the tool's downstream system (file access logs, API gateway request logs, DNS logs). Correlate by timestamp and source IP to reconstruct the parameter set.

**Step 2 — Classify each tool call against the authorization policy (Q5)**
For each tool call, retrieve the authorization policy version in effect at the session start time. Classify as: AUTHORIZED, UNAUTHORIZED, or UNDETERMINED. Document the policy version and its effective date.

**Step 3 — Identify the instruction context (Q2)**
Retrieve the system prompt version in effect and the user instruction for the session. Review all tool results consumed by the agent for injected instructions. If no injection is identified, the unauthorized action may reflect a policy gap (the agent took an action its policy should have prohibited but did not explicitly prohibit).

**Step 4 — Scope the data impact (Q3)**
For each UNAUTHORIZED tool call, determine: what data was accessed or transmitted? What is the sensitivity classification of that data? Was any data transmitted outside the authorized system boundary?

**Step 5 — Determine blast radius (Q1)**
Enumerate all downstream effects of the unauthorized action. If the agent wrote to a database, what records were modified? If the agent posted to an external endpoint, what data was transmitted and to what destination?

**Step 6 — Produce findings**

| Finding element | Required content |
|---|---|
| Root cause | Policy gap / prompt injection / model behavior anomaly |
| Unauthorized actions | Complete list with parameters and evidence basis |
| Data impact | What data, what sensitivity, was it exfiltrated? |
| Authorization policy gap | What policy change would have prevented this? |
| Remediation | Immediate (suspend session type), short-term (update policy), long-term (forensic infra improvement) |

---

## Playbook AF-02 — Prompt Injection Confirmed

**Trigger:** Investigation has identified an injected instruction in the agent's user input or in a tool result consumed by the agent, and has attributed one or more agent actions to that injected instruction.

**Severity classification:** High if the injection caused unauthorized data access; Critical if the injection caused external exfiltration or irreversible system change.

### Investigation Steps

**Step 1 — Extract and document the injection payload (Q2)**
Locate the injection payload in the evidence record. Document: the carrier (user instruction, PR description, document content, tool result), the verbatim payload text, the injection technique (direct override, role assignment, authority claim), and the position in the context window where the injection appeared.

**Step 2 — Establish causal link between injection and agent actions (Q1, Q4)**
For each unauthorized action in the tool call timeline, determine whether the action is attributable to the injection. The link is established when: (a) the action type matches the injected instruction, (b) the action parameters match the injected instruction's specifics (e.g., the exact file path or URL specified in the injection), and (c) no legitimate instruction authorized the same action.

**Step 3 — Reconstruct the injection vector**
Determine how the injection payload entered the agent's context. Common vectors:
- User-controlled input passed directly to the agent (direct injection)
- Content from a third-party source that the agent read during a tool call (indirect injection via file, PR, issue, document)
- Tool result from an upstream system that had been compromised or manipulated

**Step 4 — Assess downstream impact (Q3)**
Identify what the injected instruction caused the agent to do and what data or systems were affected. For exfiltration scenarios: identify the data elements transmitted, the destination, and the volume.

**Step 5 — Identify similar sessions**
Review audit logs for other agent sessions in the same time window. The injection vector (e.g., a malicious PR description) may have affected multiple sessions. The scope of the incident is not limited to the detected session.

**Step 6 — Produce findings**

| Finding element | Required content |
|---|---|
| Injection payload | Verbatim text, carrier, injection technique |
| Injection vector | How did the payload reach the agent's context window? |
| Causal attribution | Which agent actions are attributed to the injection? |
| Impact | Data accessed, data exfiltrated, systems affected |
| Detection gap | What detection control would have identified this injection? |
| Remediation | Input validation improvement, context isolation, detection rule |

---

## Playbook AF-03 — Unknown Provenance Artifact Introduced by Agent

**Trigger:** An agent introduced an artifact — a package, binary, configuration file, or code change — into the software delivery pipeline or production environment, and the provenance of that artifact cannot be established through standard supply chain controls (SBOM, SLSA provenance, Cosign signature).

**Severity classification:** High if the artifact is in a staging environment; Critical if the artifact has reached production or is included in a released build.

### Investigation Steps

**Step 1 — Identify the artifact and its entry point (Q1)**
Locate the artifact: where is it? What is its hash? When was it introduced? Trace the artifact's entry point to an agent action by correlating the introduction timestamp with the agent's tool call timeline.

**Step 2 — Reconstruct the artifact lineage (Q3)**
Attempt to reconstruct where the artifact came from. Check:
- Did the agent download it from an external source? (Retrieve URL from tool call parameters)
- Did the agent generate it locally? (Identify the tool call that created or wrote the artifact)
- Did the agent receive it as the output of a tool call (e.g., a dependency resolved by an AI coding assistant)?

**Step 3 — Assess trust chain integrity (Q5)**
Determine whether any authorization policy permitted the agent to introduce unsigned or unverified artifacts. If the agent operated within policy, the policy itself is the finding — the policy did not require provenance verification before artifact introduction.

**Step 4 — Quarantine the artifact**
Remove the artifact from the pipeline and production environment. Document the quarantine action with a timestamp and the investigator who executed it. Do not delete the artifact — preserve it for evidence.

**Step 5 — Assess downstream impact (Q3)**
Determine whether the artifact has been used. Was it executed? Was it included in a build? Was it deployed to production? Each downstream use is an additional scope element.

**Step 6 — Produce findings**

| Finding element | Required content |
|---|---|
| Artifact identity | Hash, type, location, introduction timestamp |
| Lineage reconstruction | Source of the artifact as established by investigation |
| Trust chain gap | Why standard supply chain controls did not block or flag this artifact |
| Impact | Environments affected, execution confirmed or ruled out |
| Remediation | Agent policy update, artifact verification control, detection rule |

---

## Playbook AF-04 — Permission Escalation via Agent

**Trigger:** An agent executed actions with authority that exceeds its defined authorization policy, and investigation indicates the agent obtained this authority through means other than the standard authorization flow (e.g., by manipulating a tool that grants permissions, by exploiting an authorization policy gap, or by using a credential obtained through a prior tool call).

**Severity classification:** High if escalated authority was used to access data; Critical if escalated authority was used to modify access controls, credentials, or infrastructure.

### Investigation Steps

**Step 1 — Reconstruct the privilege timeline (Q1, Q4)**
Build a timeline that shows the agent's authorization state at each point in the session. At session start, what tools and scopes did the agent have? Did the authorization state change during the session? Map each tool call to the authorization state in effect at the time of the call.

**Step 2 — Identify the escalation mechanism**
How did the agent obtain elevated authority? Common mechanisms:
- Tool call to an authorization management API (e.g., IAM, Vault) that the agent was erroneously permitted to invoke
- Use of a credential obtained in an earlier tool call (the agent read a secret and used it to authenticate to a privileged API)
- Exploitation of a wildcard or overly broad path in the authorization policy
- Injection-driven escalation (a prompt injection instructed the agent to request additional permissions)

**Step 3 — Assess lateral movement (Q1, Q3)**
Determine whether the escalated authority was used to access systems or data not reachable by the agent's original authorization. Map the agent's access before and after escalation. Identify any new systems or data elements accessed with escalated authority.

**Step 4 — Assess policy gap (Q5)**
Determine whether the escalation was the result of a policy gap (the agent was permitted to do something that enabled escalation) or a policy violation (the agent took an action that the policy explicitly prohibited). Both are findings; they have different remediation paths.

**Step 5 — Produce findings**

| Finding element | Required content |
|---|---|
| Escalation mechanism | How did the agent obtain elevated authority? |
| Privilege timeline | Authorization state at each phase of the session |
| Lateral movement | What additional systems or data were accessible after escalation? |
| Policy gap identified | What policy change closes the escalation path? |
| Remediation | Policy update, credential rotation, authorization architecture review |

## Framework Reference

`forensics-and-incident-response-framework/docs/agent-forensics.md`

## Hands-On Lab

→ [Lab: Executing AF-01 and AF-02 Playbooks on Simulated Incident Evidence](lab/README.md)
