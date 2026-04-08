# Lab — Constructing a 90-Day AI Security Program Roadmap

**Chapter:** 20 — Building an AI Security Program: From AI-Naive to AI-Secure
**Estimated time:** 40–55 minutes
**Difficulty:** Beginner–Intermediate
**Prerequisites:** AI security maturity model (Chapter 18); understanding of AI integration layers (Chapter 2); understanding of agent authorization (Chapter 9)

---

## Objective

Given a described organization and its current AI security maturity state, construct a 90-day AI security program roadmap. Produce a roadmap document, a metrics framework, and a one-page executive summary. This lab is scenario-driven and does not require code — it is a structured design exercise that applies the program-building concepts from Chapter 20.

---

## Setup

No installation required. Use any text editor or Python for the structured outputs.

---

## Scenario

**Organization:** MidScale Software — a 400-person SaaS company delivering a B2B analytics platform. Engineering headcount: 120. Security team: 4 people (CISO, two security engineers, one AppSec engineer).

**Current AI usage:**
- GitHub Copilot deployed for all engineers (6 months ago, no formal security review)
- CodeRabbit AI code review integrated into all repositories (3 months ago)
- One AI agent in production: a support ticket triage agent that reads ticket descriptions and categorizes/routes them. No authorization policy documented. No audit log.
- Three teams exploring AI-powered features for the product (not yet in production)

**Current security posture on AI:**
- No AI system inventory
- No AI usage policy
- No slopsquatting detection in pre-commit or CI
- Support triage agent has full read access to the internal ticket system (no scope limits)
- No forensic logging for the triage agent
- CISO has asked for an AI security roadmap for the board meeting in 90 days

**Maturity assessment result:** Level 1 — AI-Naive (based on the Chapter 18 self-assessment)

---

## Part 1 — AI System Inventory

Before building the roadmap, complete the AI system inventory for MidScale Software:

```python
ai_inventory = [
    {
        "system_name": "GitHub Copilot",
        "type": "AI coding assistant",
        "integration_layer": "Developer environment",  # Layer 1
        "users": "All 120 engineers",
        "data_categories_processed": ["Source code", "Comments", "Docstrings"],
        "current_controls": [],
        "security_review_completed": False,
        "highest_risk": "Secret exfiltration via context; hallucinated package suggestions (slopsquatting)"
    },
    {
        "system_name": "CodeRabbit AI code review",
        "type": "AI code review",
        "integration_layer": "Code review (Layer 2)",
        "users": "All engineers via pull requests",
        "data_categories_processed": ["Source code", "PR descriptions", "Comments"],
        "current_controls": [],
        "security_review_completed": False,
        "highest_risk": "PR description injection; trust escalation if AI review output treated as authoritative"
    },
    {
        "system_name": "Support ticket triage agent",
        "type": "Autonomous AI agent",
        "integration_layer": "Production operations (Layer 5)",
        "users": "Automated — no human in loop",
        "data_categories_processed": ["Support ticket text", "Customer identifiers", "Issue categories"],
        "current_controls": [],
        "security_review_completed": False,
        "highest_risk": "Prompt injection via ticket content; unbounded access to ticket system; no forensic logging"
    },
]

print("AI System Inventory — MidScale Software")
for system in ai_inventory:
    print(f"\n{system['system_name']}")
    print(f"  Integration layer: {system['integration_layer']}")
    print(f"  Highest risk: {system['highest_risk']}")
```

**Add the three teams exploring AI features to the inventory.** What information do you need to complete their entries, and how would you collect it?

---

## Part 2 — Risk Prioritization

Before building the 90-day roadmap, prioritize the risks from the inventory by likelihood and impact:

```python
risk_register = [
    {
        "risk": "Slopsquatting via Copilot hallucinated packages",
        "systems": ["GitHub Copilot"],
        "likelihood": "High",  # Copilot hallucinated packages are well-documented
        "impact": "Medium",    # Supply chain compromise requires additional exploitation
        "priority": 1,
        "mitigating_control": "Pre-commit hook + CI package existence verification"
    },
    {
        "risk": "Prompt injection via support ticket → triage agent action",
        "systems": ["Support ticket triage agent"],
        "likelihood": "Medium",  # Customers can submit arbitrary text
        "impact": "High",        # Agent has full read access to ticket system
        "priority": 2,
        "mitigating_control": "Input sanitization + authorization policy + audit log"
    },
    {
        "risk": "PR description injection into CodeRabbit review",
        "systems": ["CodeRabbit AI code review"],
        "likelihood": "Medium",
        "impact": "Medium",
        "priority": 3,
        "mitigating_control": "Output validation; do not treat AI review as authoritative security signal"
    },
    {
        "risk": "Secret exfiltration via Copilot context",
        "systems": ["GitHub Copilot"],
        "likelihood": "Low",     # Requires specific configuration or misuse
        "impact": "High",
        "priority": 4,
        "mitigating_control": "AI usage policy; .gitignore enforcement; secret scanning"
    },
    {
        "risk": "AI-powered product features in production without security review",
        "systems": ["3 teams exploring AI features"],
        "likelihood": "High",    # Teams are actively building
        "impact": "Unknown",     # Depends on features
        "priority": 5,
        "mitigating_control": "AI security review gate before production deployment"
    },
]
```

**Question:** The triage agent has full read access to the ticket system. The risk register rates the injection risk as Medium likelihood. What is the worst-case blast radius if a prompt injection succeeds against this agent, and does that blast radius change your priority ranking?

---

## Part 3 — 90-Day Roadmap Construction

Build the 90-day roadmap as a series of workstreams with weekly milestones:

```python
roadmap = {
    "organization": "MidScale Software",
    "starting_maturity": "Level 1 — AI-Naive",
    "target_maturity_at_90_days": "Level 2 — AI-Aware",
    "security_team_allocation": "0.5 FTE security engineer + 0.25 FTE AppSec engineer",

    "workstreams": [
        {
            "name": "Workstream 1 — Visibility",
            "weeks": "1–4",
            "objective": "Know what AI is in use and establish baseline governance",
            "deliverables": [
                "Complete AI system inventory (all current systems + pipeline for new ones)",
                "Draft AI usage policy (approved by CISO, communicated to all engineers by week 4)",
                "Establish AI security review gate for new AI system adoption"
            ],
            "owner": "CISO + Security Engineer",
            "effort": "Low — primarily process and documentation"
        },
        {
            "name": "Workstream 2 — Developer Environment Controls",
            "weeks": "2–6",
            "objective": "Reduce slopsquatting risk from Copilot usage",
            "deliverables": [
                "Pre-commit hook for package existence verification deployed to all repos",
                "CI/CD step for package verification added to all pipelines",
                "Developer security guidance for Copilot usage published (secret handling, package verification)"
            ],
            "owner": "Security Engineer + Platform Engineering",
            "effort": "Low-Medium — tooling integration"
        },
        {
            "name": "Workstream 3 — Triage Agent Hardening",
            "weeks": "3–8",
            "objective": "Reduce prompt injection risk and establish forensic capability for the production agent",
            "deliverables": [
                "Authorization policy documented and enforced (limit to ticket read + categorization API only)",
                "Input sanitization for ticket content before agent ingestion",
                "Audit log for every agent action (tool calls, ticket IDs accessed, categorization decisions)",
                "Human escalation trigger for suspicious ticket patterns"
            ],
            "owner": "Security Engineer + Agent developer team",
            "effort": "Medium — requires coordination with agent developer"
        },
        {
            "name": "Workstream 4 — AI Security Review Process",
            "weeks": "4–12",
            "objective": "Ensure AI-powered product features are reviewed before production",
            "deliverables": [
                "AI security review checklist created (based on OWASP LLM Top 10 + Techstream framework)",
                "Review gate added to product launch process",
                "First review completed for highest-priority team building AI feature"
            ],
            "owner": "AppSec Engineer",
            "effort": "Medium — process creation + one initial review"
        },
        {
            "name": "Workstream 5 — Board Reporting",
            "weeks": "8–12",
            "objective": "Produce board-ready AI security status report",
            "deliverables": [
                "AI security maturity assessment (Level 1 → Level 2 transition documented)",
                "Risk register summary suitable for board presentation",
                "12-month roadmap toward Level 3",
                "Metrics framework established (to be measured going forward)"
            ],
            "owner": "CISO",
            "effort": "Low — synthesis of workstream outputs"
        }
    ]
}
```

**Complete the roadmap** by adding specific week-by-week milestones for at least two workstreams.

---

## Part 4 — Metrics Framework

Define the metrics the program will track starting from day 1:

```python
metrics_framework = {
    "maturity_metrics": [
        {
            "metric": "AI security maturity score",
            "current_value": "Level 1",
            "target_at_90_days": "Level 2",
            "measurement_method": "Chapter 18 self-assessment",
            "frequency": "Quarterly"
        }
    ],
    "operational_metrics": [
        {
            "metric": "Slopsquatting detection rate",
            "current_value": "0% (no detection in place)",
            "target_at_90_days": "Detection in place; baseline established",
            "measurement_method": "Pre-commit hook and CI scan logs",
            "frequency": "Monthly"
        },
        # Add: agent authorization policy coverage
        # Add: triage agent audit log completeness
        # Add: AI security review gate compliance (% of new AI systems reviewed before production)
    ],
    "compliance_metrics": [
        {
            "metric": "AI system inventory completeness",
            "current_value": "0% (no inventory)",
            "target_at_90_days": "100% of known systems inventoried",
            "measurement_method": "Inventory review + engineering manager attestation",
            "frequency": "Quarterly"
        }
    ]
}
```

**Add the three missing operational metrics** and define their measurement methodology.

---

## Part 5 — One-Page Executive Summary

Produce a one-page executive summary suitable for the board meeting. Use the structure below:

```
AI SECURITY PROGRAM — 90-DAY ROADMAP SUMMARY
MidScale Software | April 2026

CURRENT STATE
[2–3 sentences: what AI systems are in use, what security controls exist today, what maturity level]

HIGHEST RISKS
[3 bullet points: the three highest-priority risks from the risk register, in plain language]

90-DAY PROGRAM
[3–4 bullet points: what the program will deliver in 90 days, in business terms]

EXPECTED MATURITY ADVANCEMENT
[1 sentence: from Level X to Level Y, what this means in practical terms]

INVESTMENT REQUIRED
Security team: [FTE allocation]
Engineering support: [FTE allocation, approximate]
Tooling: [any new tooling costs, or "no new tooling required"]

KEY METRICS WE WILL TRACK
[3 metrics, with current baseline and 90-day target]

BEYOND 90 DAYS
[2 sentences: what the 6-month and 12-month horizons look like]
```

---

## Reflection Questions

1. The roadmap targets Level 2 (AI-Aware) at 90 days. The CISO has asked whether the organization could reach Level 3 (AI-Defended) in 90 days instead. What additional resources would be required, what trade-offs would you make, and what is the risk of accelerating the program?

2. The triage agent workstream requires coordination with the agent developer team. In your experience or based on the framework, what is the most common form of pushback from development teams when security engineers propose audit logging and authorization policy changes, and how would you address it?

3. The metrics framework starts measuring on day 1. Some metrics (like slopsquatting detection rate) will show zero events early on — not because there are no hallucinated packages, but because detection was not in place before. How would you interpret and communicate zero-event data to the CISO in a way that is accurate about what is and is not known?

---

## Framework Reference

`ai-devsecops-framework/docs/program-guide.md`

## Learning Checkpoint

After completing this lab you should be able to:
- Construct an AI system inventory for a described organization and identify the highest-risk systems
- Build a phased 90-day AI security program roadmap with workstreams, deliverables, owners, and effort estimates
- Define a metrics framework that measures both maturity advancement and operational control effectiveness
- Produce an executive summary that communicates AI security investment in business terms
- Identify the organizational constraints (team size, coordination, board timelines) that shape program design
