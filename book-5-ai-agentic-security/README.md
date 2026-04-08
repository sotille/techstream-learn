# Book 5 — AI and Agentic Systems Security for DevSecOps

> Hands-on lab companion to *AI and Agentic Systems Security for DevSecOps* (Techstream Book Series, Volume 5).

---

## About This Book

Volume 5 covers the security engineering practices required when AI components — coding assistants, AI-powered code review, LLM-integrated CI/CD pipelines, and autonomous remediation agents — become part of the software delivery lifecycle.

The book is organized into five parts:

| Part | Chapters | Topic |
|------|----------|-------|
| Part I | 1–4 | The AI Threat Landscape in DevSecOps |
| Part II | 5–8 | Securing AI-Assisted Development |
| Part III | 9–13 | Agentic Pipeline Security |
| Part IV | 14–17 | Agent Forensics |
| Part V | 18–20 | Governance and Maturity |

**Primary framework references:** [ai-devsecops-framework](../../ai-devsecops-framework/) · [forensics-and-incident-response-framework](../../forensics-and-incident-response-framework/)

---

## Chapter Directory

Each folder contains a chapter narrative (`README.md`) and a hands-on lab (`lab/README.md`).

### Part I — The AI Threat Landscape in DevSecOps

| Folder | Chapter | Lab |
|--------|---------|-----|
| [ch01-ai-threats/](ch01-ai-threats/) | Ch 01 — Why AI Changes the DevSecOps Threat Model | Lab 01 — Detecting slopsquatting with SCA |
| [ch02-ai-integration-surface/](ch02-ai-integration-surface/) | Ch 02 — The AI Integration Surface: Five Layers of Risk | Lab — AI integration surface mapping exercise |
| [ch03-prompt-injection/](ch03-prompt-injection/) | Ch 03 — Prompt Injection: Direct, Indirect, and the DevSecOps Attack Surface | Lab 02 — Prompt injection detection in CI pipeline |
| [ch03-prompt-injection-defense/](ch03-prompt-injection-defense/) | Ch 03 (companion deep-dive) — Architectural Defense Patterns and Output Validation | Lab — Structural defense implementation |

> **Note on ch03 folders:** `ch03-prompt-injection` is the canonical chapter containing Lab 02. `ch03-prompt-injection-defense` is an extended architectural reference covering structural instruction/data separation, output validation patterns by pipeline task type, and forensic audit trail requirements — referenced from the main chapter.

### Part II — Securing AI-Assisted Development

| Folder | Chapter | Lab |
|--------|---------|-----|
| [ch05-ai-coding-assistants/](ch05-ai-coding-assistants/) | Ch 05 — AI Coding Assistants: Slopsquatting, Hallucinated Packages, and Secret Exfiltration | Lab — Hallucinated dependency detection |
| [ch06-ai-code-review/](ch06-ai-code-review/) | Ch 06 — Securing AI-Powered Code Review | Lab — PR injection attack simulation |
| [ch07-model-supply-chain/](ch07-model-supply-chain/) | Ch 07 — Model Supply Chain Security: Provenance, Scanning, and Hugging Face Risk | Lab — ModelScan and model provenance verification |
| [ch08-stride-llm-systems/](ch08-stride-llm-systems/) | Ch 08 — STRIDE Applied to LLM Systems in DevSecOps | Lab — LLM threat model construction |

### Part III — Agentic Pipeline Security

| Folder | Chapter | Lab |
|--------|---------|-----|
| [ch09-agent-authorization/](ch09-agent-authorization/) | Ch 09 — Agent Authorization: The Principle of Least Authority | Lab 03 — Agent authorization policy implementation |
| [ch10-agent-audit-trails/](ch10-agent-audit-trails/) | Ch 10 — Agent Audit Trails: Immutable Logging and Session Replay | Lab — Audit trail design and implementation |
| [ch11-multi-agent-trust/](ch11-multi-agent-trust/) | Ch 11 — Multi-Agent Systems: Chains of Trust and Cascade Compromise | Lab — Multi-agent trust boundary analysis |
| [ch12-pipeline-controls/](ch12-pipeline-controls/) | Ch 12 — Pipeline Controls for AI Components: Circuit Breakers, Approval Gates, and Input Sanitization | Lab — Circuit breakers and approval gates for AI pipeline steps |
| [ch13-ai-production-ops/](ch13-ai-production-ops/) | Ch 13 — AI in Production Operations: Autonomous Remediation Agents and Risk Governance | Lab — Progressive autonomy with blast radius limits |

### Part IV — Agent Forensics

| Folder | Chapter | Lab |
|--------|---------|-----|
| [ch14-forensics-problem/](ch14-forensics-problem/) | Ch 14 — The Agent Forensics Problem: Why Standard IR Misses Agent Incidents | Lab — Agent forensics evidence gap analysis |
| [ch15-five-forensic-questions/](ch15-five-forensic-questions/) | Ch 15 — The Five Forensic Questions Framework for Agent Incidents | Lab — Applying the Five Questions to simulated incident evidence |
| [ch16-forensics-playbooks/](ch16-forensics-playbooks/) | Ch 16 — Agent Forensics Investigation Playbooks | Lab — Executing AF-01 and AF-02 playbooks |
| [ch17-forensics-readiness/](ch17-forensics-readiness/) | Ch 17 — Agent Forensics Readiness and Forensic Infrastructure | Lab — Forensic readiness assessment and tabletop exercise |
| [ch04-agent-forensics/](ch04-agent-forensics/) | Ch 16 (Lab 04) — Full forensics session: reconstruction, injection detection, and provenance verification | Lab 04 — End-to-end agent forensics investigation |

> **Note on ch04-agent-forensics:** This folder contains Lab 04, which is referenced in the book at Chapter 16 and provides a complete end-to-end forensic investigation exercise. The `ch14`–`ch17` folders contain the chapter narratives for Part IV.

### Part V — Governance and Maturity

| Folder | Chapter | Lab |
|--------|---------|-----|
| [ch18-maturity/](ch18-maturity/) | Ch 18 — The AI Security Maturity Model: Five Levels from Naive to Secure | Lab 05 — AI security maturity self-assessment |
| [ch19-regulatory-landscape/](ch19-regulatory-landscape/) | Ch 19 — The Regulatory Landscape for AI in Software Delivery | Lab — EU AI Act and NIST AI RMF control mapping |
| [ch20-ai-security-program/](ch20-ai-security-program/) | Ch 20 — Building an AI Security Program: From AI-Naive to AI-Secure | Lab — 90-day AI security program roadmap construction |

---

## Official Labs (5 core + 16 chapter labs)

### Five Core Labs (referenced directly in the book)

| Lab | Folder | Estimated Time | Difficulty |
|-----|--------|----------------|------------|
| Lab 01 — Detecting slopsquatting with SCA | [ch01-ai-threats/lab/](ch01-ai-threats/lab/) | 45–60 min | Beginner–Intermediate |
| Lab 02 — Prompt injection detection in CI pipeline | [ch03-prompt-injection/lab/](ch03-prompt-injection/lab/) | 55–70 min | Intermediate |
| Lab 03 — Agent authorization policy implementation | [ch09-agent-authorization/lab/](ch09-agent-authorization/lab/) | 60–75 min | Intermediate–Advanced |
| Lab 04 — Agent forensics: session reconstruction, injection detection, provenance verification | [ch04-agent-forensics/lab/](ch04-agent-forensics/lab/) | 70–90 min | Advanced |
| Lab 05 — AI security maturity self-assessment | [ch18-maturity/lab/](ch18-maturity/lab/) | 40–55 min | Beginner–Intermediate |

### Chapter Labs (one per chapter, self-contained)

| Chapter | Folder | Lab Title | Estimated Time | Difficulty |
|---------|--------|-----------|----------------|------------|
| Ch 02 | [ch02-ai-integration-surface/lab/](ch02-ai-integration-surface/lab/) | AI integration surface mapping | 30–45 min | Beginner |
| Ch 03 (defense) | [ch03-prompt-injection-defense/lab/](ch03-prompt-injection-defense/lab/) | Structural defense implementation | 45–60 min | Intermediate |
| Ch 05 | [ch05-ai-coding-assistants/lab/](ch05-ai-coding-assistants/lab/) | Hallucinated dependency detection | 40–55 min | Beginner–Intermediate |
| Ch 06 | [ch06-ai-code-review/lab/](ch06-ai-code-review/lab/) | PR injection attack simulation | 55–70 min | Intermediate |
| Ch 07 | [ch07-model-supply-chain/lab/](ch07-model-supply-chain/lab/) | ModelScan and model provenance verification | 50–65 min | Intermediate |
| Ch 08 | [ch08-stride-llm-systems/lab/](ch08-stride-llm-systems/lab/) | LLM threat model construction | 60–75 min | Intermediate |
| Ch 10 | [ch10-agent-audit-trails/lab/](ch10-agent-audit-trails/lab/) | Audit trail design and implementation | 55–70 min | Intermediate–Advanced |
| Ch 11 | [ch11-multi-agent-trust/lab/](ch11-multi-agent-trust/lab/) | Multi-agent trust boundary analysis | 60–75 min | Intermediate–Advanced |
| Ch 12 | [ch12-pipeline-controls/lab/](ch12-pipeline-controls/lab/) | Circuit breakers and approval gates | 60–75 min | Intermediate–Advanced |
| Ch 13 | [ch13-ai-production-ops/lab/](ch13-ai-production-ops/lab/) | Progressive autonomy with blast radius limits | 65–80 min | Intermediate–Advanced |
| Ch 14 | [ch14-forensics-problem/lab/](ch14-forensics-problem/lab/) | Agent forensics evidence gap analysis | 50–65 min | Intermediate |
| Ch 15 | [ch15-five-forensic-questions/lab/](ch15-five-forensic-questions/lab/) | Applying the Five Questions to simulated incident evidence | 60–75 min | Intermediate–Advanced |
| Ch 16 | [ch16-forensics-playbooks/lab/](ch16-forensics-playbooks/lab/) | Executing AF-01 and AF-02 playbooks | 70–90 min | Advanced |
| Ch 17 | [ch17-forensics-readiness/lab/](ch17-forensics-readiness/lab/) | Forensic readiness assessment and tabletop exercise | 55–70 min | Intermediate–Advanced |
| Ch 19 | [ch19-regulatory-landscape/lab/](ch19-regulatory-landscape/lab/) | EU AI Act and NIST AI RMF control mapping | 45–60 min | Intermediate |
| Ch 20 | [ch20-ai-security-program/lab/](ch20-ai-security-program/lab/) | 90-day AI security program roadmap construction | 40–55 min | Beginner–Intermediate |

---

## Prerequisites

- Familiarity with CI/CD concepts (pipeline stages, artifacts, triggers)
- Basic understanding of STRIDE threat modeling
- Access to a GitHub or GitLab account for pipeline labs
- Python 3.11+ for scripted exercises
- An `ANTHROPIC_API_KEY` for labs that invoke the Claude API (Labs 01–03, Ch 12–13)

---

## How to Use This Companion

Each chapter folder contains:
- **README.md** — chapter narrative, key concepts, and framework cross-references
- **lab/README.md** — step-by-step lab instructions with expected outputs and learning checkpoints

Labs are self-contained. You do not need to complete earlier labs to attempt later ones, though Part III and Part IV labs assume familiarity with Part I and Part II concepts respectively.

---

## License

Apache License 2.0 — see [LICENSE](../../LICENSE)
