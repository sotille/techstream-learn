# Chapter 20 — Building an AI Security Program: From AI-Naive to AI-Secure

## What You Will Learn

This chapter provides a structured approach to constructing a phased AI security program anchored to the five-level maturity model from Chapter 18. You will learn to translate maturity gaps into a business-justified investment plan, define the roles and governance structures needed to sustain an AI security program, establish the metrics that demonstrate program effectiveness, and communicate AI security investment to executive stakeholders.

## Why This Matters

An AI security program that is not anchored to measurable maturity advancement is not a program — it is a list of activities. Security teams that cannot show progress against a model tend to have their budgets cut when an organization's AI adoption accelerates. The five-level maturity model provides the measurement framework; this chapter provides the program structure that drives advancement through it.

The goal is not to reach Level 5 immediately. The goal is to reach the maturity level appropriate for the organization's AI exposure and risk tolerance, and to advance systematically from wherever the organization starts.

## Key Concepts

### AI Security Program Roadmap Structure

Structure the program roadmap across three planning horizons:

**90-day horizon — Minimum viable AI security program:**
Focus on visibility and foundational controls. At the end of 90 days, the organization should be able to answer: what AI is in use, what policies govern its use, and what controls exist on the highest-risk integration points. Typical deliverables:
- AI system inventory completed
- AI usage policy established and communicated
- Developer AI assistant controls deployed (package existence verification, secret detection)
- CI/CD AI integration audit log in place
- Agent authorization policy drafted for any deployed agents

**6-month horizon — Systematic controls:**
Focus on defending the full AI integration surface. At the end of 6 months, every layer of the AI integration surface should have at least baseline controls. Typical deliverables:
- Input sanitization and output schema validation on all AI pipeline steps
- Circuit breaker pattern implemented for high-consequence AI pipeline steps
- Agent audit trail architecture in production
- Forensic readiness assessment completed with remediation roadmap in progress
- Threat model for AI systems in production (STRIDE applied)

**12-month horizon — Governance and maturity:**
Focus on program maturity, continuous assurance, and forensic readiness. At the end of 12 months, the organization should be at Level 3 (AI-Defended) with a defined path to Level 4. Typical deliverables:
- Agent authorization policies fully deployed and version-controlled
- Forensic readiness score ≥ 70% for all production agent deployments
- AI security maturity reassessment completed (compare to baseline assessment)
- Governance board established and operating on monthly cadence
- Executive-level AI security reporting in place

### Minimum Viable AI Security Program Definition

The minimum viable AI security program (MVASP) is the smallest set of controls and processes that meaningfully reduces AI-specific risk in a software delivery organization. It is designed for organizations at Level 1 (AI-Naive) that need to establish a foundation without requiring significant up-front investment.

**MVASP components:**

1. **AI inventory:** A list of every AI system in use — models, APIs, agents, AI-powered tools — with the integration layer it operates in (developer environment, code review, CI/CD, deployment, production). Updated quarterly.

2. **AI usage policy:** A written policy that specifies what AI systems are approved for use, what data categories may be processed by AI systems, and what approvals are required for new AI system adoption. Enforced through developer onboarding and tool procurement.

3. **Slopsquatting detection:** Pre-commit hook and CI/CD step that verifies package existence before installation. Reduces the highest-frequency AI-assisted supply chain attack vector.

4. **Agent authorization policy:** For any deployed AI agent, a written authorization policy specifying what tools it can use and with what parameters. Even a simple policy enforced manually is better than no policy.

5. **Incident response procedure:** A documented procedure for what to do when an AI-related security incident is suspected. Who is notified? What evidence is collected? Who has authority to suspend an agent? Even a one-page procedure is better than improvising.

The MVASP does not require significant tooling investment. It requires intentionality — making deliberate decisions about AI security rather than letting AI adoption proceed without oversight.

### AI Security Roles and Responsibilities

**AI Security Lead:** Owns the AI security program. Responsible for maintaining the AI inventory, authoring and enforcing the AI usage policy, running the threat modeling program for AI systems, and chairing the AI operations governance board. This role may be assigned to an existing senior security engineer in smaller organizations; dedicated in larger organizations.

**Platform AI Governance:** The platform or SRE team member responsible for enforcing AI security controls at the infrastructure layer — agent authorization enforcement, audit log architecture, forensic infrastructure. Works closely with the AI Security Lead.

**Product Security AI Liaison:** The AppSec or product security team member embedded with product teams that are building AI-powered features. Responsible for threat modeling AI features at design time and ensuring AI security requirements are met before release.

In smaller organizations, these three roles may be held by one or two people. The important thing is that someone owns each function — not that the org chart reflects distinct headcount.

### Metrics and KPIs for AI Security Programs

Define metrics that measure actual security outcomes, not activity metrics.

**Maturity metrics (measure program advancement):**
- AI security maturity score: current level on the five-level model, measured quarterly
- Open maturity gaps: count of Level N control gaps identified in the last assessment
- Maturity advancement rate: how many levels has the program advanced in the last 12 months?

**Operational metrics (measure control effectiveness):**
- Slopsquatting detection rate: percentage of AI-hallucinated package names caught before installation
- Agent authorization policy coverage: percentage of deployed agents with a documented, enforced authorization policy
- Forensic readiness score: average score across all production agent deployments (target: ≥70%)
- Mean time to detect AI-related incidents (MTTD): from when the incident occurred to when it was detected
- Human escalation rate for agents: percentage of agent sessions that required human escalation (too high = agent is unreliable; too low may indicate escalation triggers are not configured)

**Compliance metrics (measure regulatory posture):**
- EU AI Act classification coverage: percentage of AI systems with a completed classification under the Act
- Control mapping completion: percentage of OWASP LLM Top 10 items with a mapped control
- Regulatory gap count: open items from the last compliance assessment with no remediation plan

Present metrics at three frequencies: operational metrics monthly to the security team; maturity metrics quarterly to engineering leadership; compliance metrics semi-annually to executive leadership and the board.

### Executive Communication for AI Security Investment

Security investment decisions are made by executives who do not have technical context. Effective executive communication for AI security must:

**Anchor to business risk, not technical complexity.** "Our AI agents have unconstrained tool access" does not land. "If a developer's PR description contains a malicious instruction, our AI code review agent could post internal configuration data to an external server — we've tested this scenario in our environment" lands.

**Provide a before/after view.** Show what the current state exposes the organization to and what the proposed investment changes. The five-level maturity model provides a natural structure for this: "We are currently at Level 1. The proposed 90-day program moves us to Level 2. The risk reduction is..."

**Quantify where possible, qualify where not.** Not all AI security risk has quantifiable probability and impact. Be honest about uncertainty while still framing the consequence: "We cannot put a precise probability on a successful prompt injection against our CI/CD agent, but we can say that if it succeeds, the blast radius includes production credentials."

**Use the regulatory anchor.** EU AI Act, NIST AI RMF, and SOC 2 are increasingly requiring AI security controls. Regulatory obligation is often a more tractable justification than security risk for some executive audiences.

### Governance Board Composition and Operations

The "governance board established" milestone in the 12-month roadmap refers specifically to the AI Operations Review Board (AIORB), defined in full in [ai-devsecops-framework/docs/program-guide.md](../../ai-devsecops-framework/docs/program-guide.md). For program-building purposes, the key operational details are:

**Minimum viable AIORB (Levels 1–3):** Three roles suffice — AI Security Lead (chair), one platform engineering representative, and one representative from legal or compliance. Meeting quarterly for 60–90 minutes. Decision documentation stored in the AI security risk register.

**Why cross-functional composition matters:** Security-only governance boards consistently make decisions that are technically sound but organizationally unenforceable — the enforcement gap is what creates exceptions without documentation. Legal must be present because audit log retention decisions have GDPR and regulatory implications. Engineering leadership must be present because autonomy level decisions affect development velocity, and an engineering leader who was not in the room when the decision was made will not own the implementation.

**Decision scope discipline:** The AIORB makes four types of decisions — new agent deployment approvals, autonomy level changes, policy exception approvals, and residual risk acceptances. It does not resolve individual security incidents (IR process), approve individual tool authorization policy details (AI Security Lead), or set the AI security program budget (CISO/CTO). Scope creep dilutes the board's effectiveness; keep the agenda narrowly focused on agent governance.

### Measuring the Forensic Readiness Score

The 12-month target "Forensic Readiness Score ≥ 70% for all production agent deployments" references the Forensics Readiness Score (FRS) defined in [forensics-and-incident-response-framework/docs/agent-forensics/readiness-guide.md](../../forensics-and-incident-response-framework/docs/agent-forensics/readiness-guide.md). For program planning, here is how to use it:

**What the FRS measures:** The FRS assesses whether your agent deployment's audit instrumentation, evidence preservation, and investigation capability meet the requirements to answer the Five Forensic Questions for any session within the defined retention period. It is scored across five levels (1–5), with each level requiring the instrumentation capabilities of all lower levels.

**Scoring approach:** The FRS is a checklist assessment, not a continuous metric. Score your deployment against the FRS rubric by checking each requirement at the relevant level. The score is the highest level at which all requirements are met without gaps. A deployment that meets 8 of 9 Level-4 requirements is at Level 3, not Level 3.8 — partial credit does not apply.

**Interpreting the 70% target:** "Forensic readiness score ≥ 70%" means all production agents must score at Level 3 or higher (Level 3 corresponds approximately to meeting 60–70% of the full FRS requirements). The ≥ 70% formulation in the metrics section refers to the percentage of production agents that have been assessed and meet the Level-3 threshold — it is a coverage metric, not a continuous score.

**Practical measurement cadence:** Run the FRS assessment for each new production agent deployment before go-live. Re-run quarterly for existing deployments (agent changes, system prompt updates, and policy changes can affect the score). The AIORB reviews FRS scores at its quarterly meeting.

---

### Program Review Cadence and Continuous Improvement

**Monthly:** Operational metrics review. Review human escalation events, circuit breaker activations, and any AI-related incidents or near-misses. Update the AI system inventory. Review any new AI system adoption requests.

**Quarterly:** Maturity assessment refresh. Re-score the organization against the five-level model. Review progress against the 90-day and 6-month roadmap. Update priorities based on new threat intelligence (new attack patterns, new OWASP LLM Top 10 updates, EU AI Act guidance updates).

**Annually:** Full program review. Benchmark against external frameworks and peer organizations (where data is available). Reassess the AI system inventory for completeness. Commission an independent tabletop exercise of the forensic readiness program. Set the 12-month roadmap for the coming year.

## Framework Reference

`ai-devsecops-framework/docs/program-guide.md`

## Hands-On Lab

→ [Lab: Constructing a 90-Day AI Security Program Roadmap](lab/README.md)
