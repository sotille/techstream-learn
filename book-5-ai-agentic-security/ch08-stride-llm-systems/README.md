# Chapter 8 — STRIDE Applied to LLM Systems in DevSecOps

## What You Will Learn

This chapter applies the STRIDE threat model systematically to LLM-integrated DevSecOps systems. You will learn how each STRIDE category maps to LLM-specific threats, construct a data flow diagram for a representative AI-assisted pipeline, and derive a prioritized control set from the threat model output. The goal is a structured, repeatable threat modeling approach that produces actionable security requirements — not a checklist of generic AI risks.

## Why This Matters

STRIDE is the dominant threat modeling method in enterprise security programs. Teams that already use STRIDE for traditional systems need a mapping that extends the method to cover LLM-specific attack categories without discarding their existing threat modeling investment. Without this mapping, LLM systems are either modeled using generic STRIDE (which misses LLM-specific threats) or excluded from threat modeling entirely (which leaves the attack surface unanalyzed).

The five LLM-specific threat categories that STRIDE does not naturally capture — prompt injection, context window manipulation, model inference attacks, jailbreaking embedded security tooling, and non-deterministic output exploitation — each map to one or more STRIDE categories with appropriate extension. This chapter provides those mappings and demonstrates their application to a concrete DevSecOps scenario.

## Key Concepts

### STRIDE Categories: Standard and LLM-Extended

| STRIDE | Standard threat | LLM-extended threat |
|--------|----------------|---------------------|
| **Spoofing** | Impersonating a user or service identity | Agent identity spoofing in multi-agent systems; model identity substitution (serving a different model than declared) |
| **Tampering** | Modifying data in transit or at rest | Prompt manipulation; context window poisoning; system prompt override via indirect injection; training data poisoning in fine-tuned models |
| **Repudiation** | Denying an action occurred | Lack of agent action logging; absence of tool call audit records; non-determinism making replay impossible; deleted context windows |
| **Information Disclosure** | Exposing data to unauthorized parties | Training data extraction attacks; system prompt leakage; cross-conversation context leakage; secret exfiltration through AI assistant integrations |
| **Denial of Service** | Making a system unavailable | Prompt flooding to exhaust token budgets; jailbreaking to consume excess compute; adversarial inputs that cause infinite tool call loops |
| **Elevation of Privilege** | Gaining unauthorized capabilities | Tool-call escalation (an agent invoking tools beyond its authorization scope); jailbreaking to remove safety guardrails; privilege inheritance in multi-agent orchestrators |

### Data Flow Diagram for a Representative AI-Assisted CI/CD Pipeline

The threat model scope for this chapter covers a pipeline with three AI integration points:

1. **AI code review agent** — reads PR content (diff, description, comments) and produces security findings
2. **AI vulnerability triage agent** — reads SAST scanner output and prioritizes findings for human review
3. **AI remediation agent** — reads triage output and proposes code changes (requires repository write access)

```
[Developer PR] --> [AI Code Review Agent] --> [Review Findings DB]
                          |
              [PR Content: untrusted]

[SAST Scanner Output] --> [AI Triage Agent] --> [Prioritized Finding Queue]
                                |
                    [Scanner Output: trusted]

[Prioritized Finding Queue] --> [AI Remediation Agent] --> [Repository (write)]
                                        |
                            [Finding Context + Codebase: semi-trusted]
```

Trust boundaries:
- PR content is **untrusted** — any contributor can control it
- SAST scanner output is **trusted** (produced by pipeline-controlled tools)
- Repository write access is **high-value target** — requires explicit authorization gate

### Threat Identification by Component

**AI Code Review Agent:**
- T (Tampering): Indirect prompt injection via PR description manipulates review output
- E (Elevation of Privilege): Injected instruction causes agent to invoke out-of-scope tools (e.g., posting to external webhook)
- R (Repudiation): No audit record of which prompt was used to produce which finding

**AI Triage Agent:**
- I (Information Disclosure): System prompt containing internal severity classification logic is leaked via extraction attack
- S (Spoofing): Attacker-controlled SAST finding content mimics internal metadata to manipulate triage ranking
- D (Denial of Service): Adversarial SAST output triggers infinite classification loop

**AI Remediation Agent:**
- E (Elevation of Privilege): Agent escalates from read to write operations through tool-call manipulation
- T (Tampering): Attacker-controlled finding context causes agent to propose malicious code changes
- R (Repudiation): Repository write operations lack correlation to specific agent session and authorization context

### Control Derivation from Threat Model

For each identified threat, derive a control:

| Threat | Control |
|--------|---------|
| Indirect injection via PR content (T) | Input sanitization; output schema validation |
| Out-of-scope tool invocation (E) | Tool authorization policy; POLA enforcement |
| Missing review audit record (R) | Append-only review log with session ID, prompt hash, and output hash |
| System prompt extraction (I) | System prompt as sensitive asset; extraction detection via canary strings |
| Adversarial SAST output spoofing (S) | SAST output signed at generation; signature verified before AI ingestion |
| Classification loop (D) | Triage timeout and fallback to human queue |
| Remediation privilege escalation (E) | Explicit human approval gate before any repository write by AI agent |
| Malicious code proposal via context (T) | Diff review by deterministic static analysis before merge |
| Missing remediation audit trail (R) | All agent-proposed changes linked to session ID, authorization record, and finding ID |

### Threat Prioritization Using DREAD for AI Systems

DREAD (Damage, Reproducibility, Exploitability, Affected users, Discoverability) provides a numeric priority for each threat. AI-specific adjustments:

- **Reproducibility:** LLM non-determinism reduces reproducibility. Score lower when attack requires specific model state, higher when attack is input-deterministic (e.g., a crafted PR description).
- **Exploitability:** Score higher when the attack vector is accessible to external contributors (e.g., PR descriptions) versus internal actors only.
- **Discoverability:** Score higher when the attack surface is documented in public LLM security research (OWASP LLM Top 10 categories).

## Framework Reference

`ai-devsecops-framework/docs/threat-modeling.md`

## Hands-On Lab

→ [Lab: LLM Threat Model Construction for a DevSecOps Pipeline](lab/README.md)
