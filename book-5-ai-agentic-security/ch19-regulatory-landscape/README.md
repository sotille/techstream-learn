# Chapter 19 — The Regulatory Landscape for AI in Software Delivery

## What You Will Learn

This chapter maps the regulatory requirements that apply to organizations using AI in software delivery to the DevSecOps controls already defined in this framework. You will understand how the EU AI Act classifies AI systems used in CI/CD pipelines, apply the NIST AI RMF core functions to DevSecOps AI use cases, and use the OWASP LLM Top 10 as a practical control reference. The goal is a compliance posture that uses controls your security program already knows — not a separate AI compliance program built from scratch.

## Why This Matters

AI regulatory requirements are maturing faster than organizational compliance programs. The EU AI Act entered into force in August 2024 with staggered compliance dates. NIST published the AI RMF in January 2023, and NIST SP 800-218A (Secure Software Development for AI) followed in 2024. OWASP LLM Top 10 v1.1 is already referenced in procurement requirements for AI-integrated software.

Engineering teams that embedded AI in their delivery pipelines before these frameworks matured are now discovering compliance gaps. Teams that are adding AI components now must design compliance in from the start. In both cases, the most efficient path is mapping existing DevSecOps controls to AI regulatory requirements — not building a parallel compliance program.

## Key Concepts

### EU AI Act: Classification of AI Systems in Software Delivery

The EU AI Act uses a risk-tiered classification. For AI systems used in software delivery, the relevant tiers are:

**Prohibited AI systems:** AI systems that exploit vulnerabilities of specific groups, use subliminal manipulation, or deploy social scoring. No standard DevSecOps AI use case falls in this category.

**High-risk AI systems (Annex III):** The Act defines eight categories of high-risk AI. For software delivery, the most relevant is Article 6(2) and Annex III, section 1(b): AI systems used in employment and worker management contexts. An autonomous AI remediation agent that can create, modify, or close work items — effectively managing engineering workflow — may qualify as high-risk under this interpretation.

High-risk AI systems require:
- Risk management system (Article 9)
- Data governance documentation (Article 10)
- Technical documentation (Article 11)
- Automatic logging (Article 12)
- Human oversight measures (Article 14)
- Accuracy, robustness, and cybersecurity requirements (Article 15)

**Limited-risk AI systems:** AI systems with transparency obligations. AI-powered code review and vulnerability triage agents that interact with humans must disclose that the interaction involves an AI system (Article 50). This requirement applies to any PR comment or security finding posted by an AI agent.

**Minimal-risk AI systems:** AI systems not in the above categories. Most AI coding assistant integrations and automated testing tools fall here. No mandatory obligations apply, though the Act encourages voluntary codes of conduct.

**Control mapping for high-risk AI:**

| EU AI Act requirement | Techstream control |
|---|---|
| Risk management system (Art. 9) | STRIDE threat model for LLM systems (Ch. 8); ai-devsecops-framework/docs/threat-modeling.md |
| Data governance (Art. 10) | Agent authorization policy (Ch. 9); data handling policies for AI assistant context |
| Technical documentation (Art. 11) | Agent audit trail (Ch. 10); framework documentation |
| Automatic logging (Art. 12) | Immutable agent audit trail (Ch. 10); tool call logs |
| Human oversight (Art. 14) | Human approval gates for high-consequence AI actions (Ch. 12) |
| Accuracy and cybersecurity (Art. 15) | Output schema validation; circuit breakers; model supply chain security (Ch. 7) |

### NIST AI RMF: Core Functions Applied to DevSecOps

The NIST AI Risk Management Framework organizes AI risk management into four core functions: Govern, Map, Measure, Manage.

**Govern:** Establish policies, accountability, and organizational structures for AI risk.
- DevSecOps mapping: AI usage policies covering which AI components are permitted in the pipeline, under what conditions, and with what authorization requirements. The governance owner is the platform security team or AI security lead.

**Map:** Identify and categorize AI risks in context.
- DevSecOps mapping: STRIDE threat modeling for each AI pipeline component (Ch. 8). Risk mapping must include trust boundary enumeration and data flow classification.

**Measure:** Analyze and assess AI risks quantitatively.
- DevSecOps mapping: DREAD scoring for LLM threats (Ch. 8); AI security maturity assessment (Ch. 18); circuit breaker anomaly rates and alert frequencies as ongoing risk metrics.

**Manage:** Prioritize and implement risk treatments; monitor and respond.
- DevSecOps mapping: Implementation of pipeline controls (Ch. 12); agent authorization policies (Ch. 9); forensic readiness program (Ch. 17); incident response playbooks for AI components (Ch. 16).

**Control mapping for NIST AI RMF:**

| NIST AI RMF function | DevSecOps implementation |
|---|---|
| GOVERN 1.1 — Policies established | AI pipeline component policy; acceptable use policy for AI coding assistants |
| GOVERN 2.2 — Accountability assigned | AI security lead role; platform team ownership of AI pipeline controls |
| MAP 1.5 — Risks identified | STRIDE-LLM threat model per component |
| MAP 2.3 — Scientific evidence considered | OWASP LLM Top 10; published AI attack research |
| MEASURE 1.1 — Risk measurement methodology | DREAD-LLM scoring; maturity model assessment |
| MEASURE 2.5 — AI risks monitored | Circuit breaker metrics; audit trail anomaly detection |
| MANAGE 1.3 — Risk treatments implemented | Pipeline controls; authorization policies; forensic readiness |
| MANAGE 4.2 — Incidents responded to | AI-specific IR playbooks (Ch. 16) |

### OWASP LLM Top 10 as a Practical Control Reference

The OWASP LLM Top 10 provides an attack-category taxonomy that maps directly to pipeline controls. Each category has one or more controls in the Techstream framework:

| OWASP LLM category | DevSecOps relevance | Techstream control |
|---|---|---|
| LLM01 — Prompt Injection | Highest risk for pipeline-integrated LLMs | Ch. 3 (detection); Ch. 6 (code review); Ch. 12 (sanitization) |
| LLM02 — Insecure Output Handling | Unvalidated AI output consumed by downstream steps | Output schema validation (Ch. 12) |
| LLM03 — Training Data Poisoning | Fine-tuned models in pipeline tooling | Model supply chain security (Ch. 7) |
| LLM04 — Model Denial of Service | Prompt flooding exhausting compute budgets | Circuit breaker rate limiting (Ch. 12) |
| LLM05 — Supply Chain Vulnerabilities | Compromised model weights or LLM dependencies | Model provenance and scanning (Ch. 7) |
| LLM06 — Sensitive Information Disclosure | System prompt extraction; cross-session data leakage | System prompt as sensitive asset; isolation controls |
| LLM07 — Insecure Plugin Design | Agent tools with insufficient authorization | POLA and tool authorization (Ch. 9) |
| LLM08 — Excessive Agency | AI agents taking high-impact actions without oversight | Human approval gates; authorization scopes (Ch. 9, 12) |
| LLM09 — Overreliance | Humans accepting AI security findings without scrutiny | Two-tier finding model; AI-human separation (Ch. 6) |
| LLM10 — Model Theft | Exfiltration of proprietary models or system prompts | Access controls; egress monitoring |

### ISO/IEC 42001 AI Management System

ISO/IEC 42001 defines an AI management system (AIMS) standard analogous to ISO 27001 for information security. For DevSecOps teams, the most relevant clauses are:
- Clause 6.1.2: AI risk assessment methodology
- Clause 8.4: AI system impact assessment
- Clause 9.1: Monitoring and measurement of AI system performance
- Clause 10.2: Nonconformity and corrective action for AI systems

Organizations already certified to ISO 27001 should integrate AI risk management into the existing ISMS scope rather than building a separate AIMS.

### NIST SP 800-218A: Secure Software Development for AI

NIST SP 800-218A extends the Secure Software Development Framework (SSDF) to AI systems. Key additions relevant to DevSecOps:
- AI component provenance verification in the software supply chain
- Training data integrity assurance
- Model behavior testing before deployment
- Monitoring of AI component behavior in production

Control mapping: Model supply chain security (Ch. 7) addresses provenance; circuit breakers and audit trails (Ch. 12, Ch. 10) address production monitoring.

## Framework Reference

`ai-devsecops-framework/docs/regulatory-mapping.md`

## Hands-On Lab

→ [Lab: EU AI Act and NIST AI RMF Control Mapping](lab/README.md)
