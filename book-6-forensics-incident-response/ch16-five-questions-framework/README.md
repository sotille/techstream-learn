# Chapter 16 — The Five Questions Framework for Agent Forensics

## What You Will Learn

This chapter introduces the Five Questions Framework (FQF) — the structured methodology for investigating incidents involving AI agent components. You will learn why standard IR questions are insufficient for agent incidents, what the five forensic questions are and what evidence is required to answer each, and how to apply the framework to produce a complete and legally defensible account of an agent-involved incident.

## Why This Matters

When an AI agent takes an unexpected action — or is alleged to have taken an action it should not have taken — the investigation faces a challenge that does not arise in traditional software forensics: the agent's reasoning is not fully reconstructable from deterministic state. The same inputs to an AI component may produce different outputs on different invocations. Without a structured framework designed for this property, investigators either over-conclude (attributing intent where none can be established) or under-conclude (failing to establish what actually occurred because perfect reconstruction is unavailable).

The Five Questions Framework provides a forensically sound approach: it specifies what can be established from evidence, what can only be inferred probabilistically, and what cannot be determined. This discipline is essential when investigation findings will be used in legal proceedings, regulatory responses, or adversarial contexts.

## The Five Questions

**Q1 — What was the agent authorized to do?** Establishes the legitimate scope of the agent's actions from the tool authorization policy, session configuration, and approval gate records at the time of the incident. This is the baseline against which actual behavior is measured.

**Q2 — What did the agent actually do?** Establishes the agent's executed actions from tool call audit logs, API call records, and any side effects observable in external systems. This question is answered with evidence, not inference — only tool calls with audit log records can be treated as established facts.

**Q3 — What inputs did the agent receive?** Reconstructs the agent's context window at the time of the relevant actions, including any injected content that may have influenced behavior. This question is the hardest to answer completely because context windows are rarely stored in full by default.

**Q4 — Was the agent's behavior consistent with its authorization?** Compares Q1 and Q2 to identify authorized actions, unauthorized actions, and actions in the ambiguous zone (authorized tools used in unexpected ways). This comparison produces the findings that drive remediation and potential attribution.

**Q5 — What could not be determined?** Documents the evidentiary gaps — what inputs cannot be reconstructed, what reasoning cannot be verified, what actions have no audit record. This question is as important as the others: explicitly scoping what is unknown prevents over-confident conclusions and supports legal defensibility.

## What You Will Practice

This chapter's lab applies the Five Questions Framework to two agent incident scenarios. For each scenario you will:

- Identify the available evidence for each of the five questions
- Produce answers with explicit evidence citations and confidence levels
- Document evidentiary gaps in the Q5 section
- Assess whether the agent's behavior can be characterized as authorized, unauthorized, or undetermined

## Lab

See [lab/README.md](lab/README.md) for the guided Five Questions Framework application exercises.
