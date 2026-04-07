# Chapter 4: Agent Forensics

## What Is Agent Forensics?

When something goes wrong in a traditional software system, incident responders reach for familiar tools: server logs, network captures, process trees, file system timelines. The mental model is linear — a human clicked something, a request traveled somewhere, a file changed. Follow the thread backward and you find the cause.

AI agents break that model completely.

An agent does not execute a single deterministic path. It reasons, selects tools, generates intermediate outputs, and feeds those outputs back into its own context — all without a human in the loop for each individual decision. When an agent takes an action you didn't expect, "what happened" is not just a question of which API was called. It is a question of *why the agent decided to call it*, and whether that decision was driven by the agent's legitimate task instructions or by something an adversary injected into its context.

**Agent forensics** is the discipline of reconstructing, analyzing, and attributing the behavior of autonomous AI agents after an incident. It draws from traditional digital forensics — log analysis, timeline reconstruction, artifact provenance — but requires a fundamentally different analytical framework to answer the questions that matter for agent incidents.

## Why Standard IR Fails for Agent Incidents

Standard incident response assumes intent is human. When a process runs an unexpected command, analysts look for a human attacker who typed it or malware that was installed. The evidence chain leads to an external actor.

With agents, the "attacker" may be the agent itself — not because the model is malicious, but because it was manipulated. A prompt injection embedded in a pull request description, a tool response that overrode task instructions, a misconfigured authorization policy that left a capability gap: any of these can cause an agent to take real-world actions that no human authorized. The agent is simultaneously the victim and the instrument of the attack.

Standard log analysis also fails because agent behavior is context-dependent. The same tool call — say, `github_push` — might be entirely legitimate in one session and deeply suspicious in another, depending on what the agent was asked to do, what content it read during that session, and what its authorization policy covered. You cannot assess a tool call in isolation.

## The Five Forensic Questions Model

Effective agent forensics organizes the investigation around five questions, asked in order:

1. **What was the agent authorized to do?** Recover the system prompt, authorization policy version, and task source at session start.
2. **What did the agent actually do?** Reconstruct the complete, ordered sequence of tool calls from the session log.
3. **Where did each action come from?** For each tool call, identify whether it was driven by the original task instructions or by content the agent read during the session.
4. **Was any external content anomalous?** Look for content — from tool responses, retrieved documents, PR descriptions, webhook payloads — that contained instruction-like language inconsistent with the data source type.
5. **What artifacts did the agent produce, and can they be trusted?** Verify the signing identity and authorization chain for any code, configuration, or deployment artifact the agent created or pushed.

## What You Will Learn

This chapter's lab walks you through a realistic agent security incident from three angles, each corresponding to one of the core forensic disciplines:

- **Exercise 1** teaches session log reconstruction: given a raw tool call log, you will rebuild the session timeline, identify authorization boundaries, and locate the specific action that exceeded the agent's policy scope.

- **Exercise 2** teaches prompt injection detection in logs: given a conversation log and tool call log for the same session, you will build a turn-by-turn timeline, identify the external content that changed the agent's behavior, and produce a structured finding that would hold up in a security review.

- **Exercise 3** teaches artifact provenance verification: using Cosign verification output and a matching tool call log, you will determine whether a production artifact was created by a human-authorized agent session or was the product of a compromised one.

All three exercises cover the same incident — a triage agent that was manipulated via a PR description into pushing an unauthorized artifact to production. By the end of the lab, you will be able to tell the complete story of that incident from log evidence alone.
