# Lab: Agent Forensics

**Difficulty:** Intermediate
**Estimated time:** 60–90 minutes
**Prerequisites:** Basic `jq` familiarity, conceptual understanding of AI agents and tool use

## Background

The Acme Corp security team has escalated an incident involving their automated triage agent, `acme-triage-bot`. The agent normally triages incoming GitHub pull requests: it reads PR metadata, queries an internal vulnerability database, and files GitHub issues for findings. It is explicitly **not** authorized to push code.

Yesterday, a commit appeared in the `main` branch of `acme-corp/infra-deploy` that no human claims to have pushed. Artifact signing logs confirm the commit was signed by the agent's identity. The three exercises in this lab reconstruct the full incident from log evidence.

All example files are in `examples/`.

---

## Exercise 1: Reconstruct an Agent Session from Tool Call Logs

### Goal

Reconstruct the complete timeline of agent session `sess-4f8a91c2` from the tool call log and identify the action that exceeded the agent's authorization scope.

### Files

- `examples/agent-session-log.json`

### Steps

**Step 1.1 — Find the session start event and recover the authorization scope.**

```bash
jq '.events[] | select(.event_type == "session_start")' examples/agent-session-log.json
```

Expected output fields: `session_id`, `agent_id`, `authorization_policy_version`, `system_prompt_hash`, `allowed_tools`.

Record the value of `allowed_tools`. This is the ground truth for what the agent was permitted to call.

**Step 1.2 — Reconstruct the tool call sequence in chronological order.**

```bash
jq '[.events[] | select(.event_type == "tool_call")] | sort_by(.timestamp)' \
  examples/agent-session-log.json
```

Read through the output. Note the `tool_name`, `authorization_decision`, and `timestamp` for each entry.

**Step 1.3 — Extract only the ALLOW decisions.**

```bash
jq '[.events[] | select(.event_type == "tool_call" and .authorization_decision == "ALLOW")] \
  | sort_by(.timestamp) | .[] | {timestamp, tool_name, params}' \
  examples/agent-session-log.json
```

**Step 1.4 — Extract only the DENY decisions.**

```bash
jq '[.events[] | select(.event_type == "tool_call" and .authorization_decision == "DENY")] \
  | .[] | {timestamp, tool_name, denial_reason}' \
  examples/agent-session-log.json
```

Note which tool was denied and why. This represents the policy working as intended.

**Step 1.5 — Find tool calls that were ALLOW but are NOT in the `allowed_tools` list from Step 1.1.**

This is the critical step. A policy gap exists when a tool call is permitted at runtime despite not being in the agent's declared authorization scope. Run:

```bash
jq '
  .events[] | select(.event_type == "session_start") | .allowed_tools as $allowed |
  (input | .events[] | select(.event_type == "tool_call" and .authorization_decision == "ALLOW") |
    select(.tool_name | IN($allowed[]) | not) |
    {tool_name, timestamp, params, authorization_decision, policy_gap_note})
' examples/agent-session-log.json examples/agent-session-log.json
```

Alternatively, inspect the output from Step 1.3 manually against the `allowed_tools` list.

**Step 1.6 — Write your investigation summary.**

In your own words (one paragraph), answer:
- What was the agent's declared authorization scope?
- What tools did it actually call?
- Which call exceeded scope, and what did it do?
- Was there also a DENY? What does the presence of both a DENY and an out-of-scope ALLOW tell you about the policy?

Compare your summary to the answer key in `examples/lab-solutions.md` when done.

---

## Exercise 2: Detect Prompt Injection Retroactively in Logs

### Goal

Using the conversation log for the same session, identify the turn where the agent's behavior changed and determine whether the change is consistent with a prompt injection attack originating from external content.

### Files

- `examples/session-conversation.json`
- `examples/agent-session-log.json` (from Exercise 1)

### Steps

**Step 2.1 — List all turns in the conversation with their roles and content sources.**

```bash
jq '.turns[] | {turn_id, role, content_source, content_preview: .content[:120]}' \
  examples/session-conversation.json
```

Read the output carefully. Note the `content_source` field — this tells you where the content originated (task instruction, agent reasoning, tool response, external document, etc.).

**Step 2.2 — Build a turn-by-turn timeline.**

Create a table (on paper or in a text file) with columns:

| Turn | Role | Content Source | Behavioral Category |
|------|------|----------------|---------------------|
| ...  | ...  | ...            | normal / anomalous  |

For `behavioral_category`, mark a turn as **anomalous** if the agent's output in that turn is inconsistent with the task it was given at session start.

**Step 2.3 — Identify the first anomalous turn.**

```bash
jq '.turns[] | select(.behavioral_flag == "anomalous")' \
  examples/session-conversation.json
```

Note the `turn_id` and `content_source` of the first anomalous turn.

**Step 2.4 — Find the external content turn that immediately preceded the behavioral change.**

The principle: prompt injection requires that the agent *read* the malicious content *before* it acts on it. Look at the turn just before the first anomalous turn.

```bash
jq '.turns[] | select(.content_source != null and (.content_source | startswith("github_")))' \
  examples/session-conversation.json
```

Examine the full content of any turn where content came from an external GitHub source:

```bash
jq '.turns[] | select(.content_source == "github_pr_description") | .content' \
  examples/session-conversation.json
```

**Step 2.5 — Extract the injection string.**

Read the PR description content. Look for instruction-like language that is anomalous for a PR description — directives addressed to the reader (the agent) rather than descriptive text about the change.

Write down the exact injection string you found.

**Step 2.6 — Correlate with the tool call log.**

Confirm that the tool call matching the injected instruction appears in `agent-session-log.json` *after* the timestamp of the turn where the PR description was read.

```bash
# Get the timestamp of the PR description read
jq '.turns[] | select(.content_source == "github_pr_description") | .timestamp' \
  examples/session-conversation.json

# Confirm github_push appears after that timestamp
jq '[.events[] | select(.event_type == "tool_call" and .tool_name == "github_push")] \
  | .[] | {timestamp, tool_name, params}' \
  examples/agent-session-log.json
```

**Step 2.7 — Classify the finding.**

Answer the following:

1. Does the behavioral change (attempting a push) directly match the language of the injected instruction?
2. Did the agent have any task-legitimate reason to push code?
3. Is the timing consistent — did the read precede the action?
4. What content source type was the vector (PR description, issue body, tool response, etc.)?

Write a two-paragraph finding report in the format:

> **Finding:** [One sentence stating what happened]
> **Evidence:** [Bullet list of supporting log references]
> **Classification:** Prompt injection via [vector] — [Confirmed / Probable / Possible]

Compare your report to the answer key in `examples/lab-solutions.md`.

---

## Exercise 3: Verify Agent-Created Artifact Provenance

### Goal

Using Cosign verification output and a matching tool call log entry, determine whether the artifact found in the `acme-corp/infra-deploy` repository was created by a human-authorized agent session.

### Files

- `examples/cosign-verify-output.json`
- `examples/provenance-tool-call.json`

### Steps

**Step 3.1 — Examine the Cosign verification output.**

```bash
jq '.' examples/cosign-verify-output.json
```

Note the following fields:
- `certificate.subject` — the signing identity
- `certificate.oidc_issuer` — the identity provider that issued the signing certificate
- `certificate.workflow_ref` — the GitHub Actions workflow that ran the signing step
- `bundle.verification_status` — whether the signature is cryptographically valid
- `session_id` — the agent session that performed the signing action

**Step 3.2 — Confirm the signing identity is an agent, not a human.**

A human-signed commit would have a certificate subject matching a human GitHub user (e.g., `https://github.com/alice`). An agent-signed commit will have a subject matching a service account or agent identity. What does the subject show?

```bash
jq '.certificate.subject' examples/cosign-verify-output.json
```

**Step 3.3 — Cross-reference the session ID against the tool call log.**

```bash
jq '{session_id, tool_name, timestamp, authorized_by, task_source, authorization_decision}' \
  examples/provenance-tool-call.json
```

Note the values of:
- `authorized_by` — who (human or system) approved this specific action
- `task_source` — where the instruction to push originated
- `authorization_decision` — what the policy engine decided

**Step 3.4 — Determine if there was human authorization.**

A properly governed agent push should have either:
- A non-empty `authorized_by` field referencing a human approver, OR
- A task source of `human_task_request` or equivalent direct human instruction

Does this tool call entry meet either condition?

**Step 3.5 — Reconcile the policy decision with the authorization scope.**

From Exercise 1, you know the agent's `allowed_tools` list. From the tool call entry, you can see the `authorization_decision`. How can a `github_push` call receive an ALLOW decision if it is not in `allowed_tools`?

Read the `policy_gap_note` field:

```bash
jq '.policy_gap_note' examples/provenance-tool-call.json
```

**Step 3.6 — Produce your provenance verdict.**

Write a provenance verdict in the following format:

> **Artifact:** [artifact identifier from cosign output]
> **Signing identity:** [certificate subject]
> **Session:** [session_id]
> **Human authorized:** Yes / No — [reason]
> **Root cause:** [how the unauthorized push was possible]
> **Verdict:** UNTRUSTED / TRUSTED

Compare your verdict to the answer key in `examples/lab-solutions.md`.

---

## Putting It All Together

You have now reconstructed the full incident from three angles:

1. **Exercise 1** identified that session `sess-4f8a91c2` called `github_push` despite it not appearing in the agent's `allowed_tools` — a policy gap.
2. **Exercise 2** identified that the agent read a PR description containing an injected instruction directing it to push, and that the push action followed immediately.
3. **Exercise 3** confirmed that the artifact in production was signed by the agent in that session, with no human authorization and a task source of `prompt_injection_via_pr_description`.

The combined picture: an attacker embedded a push directive in a PR description. The triage agent read it, interpreted it as a legitimate instruction, and executed it. The authorization policy denied one push attempt (the policy partially worked) but an ALLOW slipped through due to a gap in the policy's branch-scoping rules. The resulting artifact is in production and must be treated as untrusted until the push is reverted and the policy gap is closed.
