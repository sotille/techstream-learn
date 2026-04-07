# Lab 1 — Calculating the Cost of Late Security Detection

**Estimated time:** 30–45 minutes
**Difficulty:** Beginner
**Prerequisites:** None — this lab uses a spreadsheet model and reflection exercises, not technical tooling.
**Format:** Individual or team exercise (team exercise produces richer results)

---

## Objective

Apply the defect cost amplification model to your organization's (or a hypothetical organization's) actual security defect data. By the end of this lab, you will have a concrete business case for investing in earlier security detection — expressed in developer hours, incident response costs, and business risk.

---

## Background: The Defect Cost Amplification Model

Research consistently shows that defects cost more to fix the later they are discovered. The following multipliers are widely cited and consistently reproduced in studies of software defect economics:

| Discovery Stage | Relative Cost to Fix | Example (1 hour to fix at commit time) |
|---|---|---|
| At commit / pre-commit | 1x | 1 hour |
| In CI pipeline (minutes after commit) | 2–5x | 2–5 hours |
| In QA / staging | 10–20x | 10–20 hours |
| In penetration test / security review | 30–50x | 30–50 hours |
| In production (before breach) | 100x | 100 hours |
| Post-breach | 300–1000x | 300–1000 hours |

These multipliers reflect the compound cost of: bug reproduction, root cause analysis, fix implementation, re-testing, deployment, documentation, and communication — all of which increase as more time passes and more systems are affected.

---

## Step 1 — Gather Your Data (or Use the Provided Estimates)

If you have access to your organization's data, collect:

1. **Number of security defects discovered per month**, by stage (pre-commit, CI, QA, pentest, production, post-breach)
2. **Average time to fix a security defect discovered at the earliest stage** (your baseline)
3. **Average hourly cost of developer/security engineer time** (fully loaded: salary + overhead, typically $80–200/hour)
4. **Number of incidents in the last 12 months** that reached production
5. **Average incident response cost** for those incidents (people time + tooling + potential breach notification)

If you do not have this data, use the following hypothetical baseline for a 200-person engineering organization:

| Stage | Defects/Month | Baseline Fix Time |
|---|---|---|
| Pre-commit | 0 (no tooling yet) | 1 hour |
| CI pipeline | 0 (no SAST/SCA yet) | 1 hour |
| QA | 5 | 1 hour |
| Penetration test | 10 | 1 hour |
| Production (pre-breach) | 3 | 1 hour |
| Post-breach incidents | 1 per quarter | — |

---

## Step 2 — Calculate Current State Cost

For each row in your data, calculate:

```
Cost per defect at stage = Baseline fix time × Stage multiplier × Hourly rate
Monthly cost at stage = Defects per month × Cost per defect at stage
```

Example calculation (using hypothetical data, $120/hour, mid-range multipliers):

| Stage | Defects/Month | Multiplier | Fix Time | Hourly Rate | Monthly Cost |
|---|---|---|---|---|---|
| QA | 5 | 15x | 15 hours | $120 | $9,000 |
| Penetration test | 10 | 40x | 40 hours | $120 | $48,000 |
| Production | 3 | 100x | 100 hours | $120 | $36,000 |
| Post-breach | 0.25 (1/quarter) | 500x | 500 hours | $120 | $15,000/month avg |
| **Total** | | | | | **~$108,000/month** |

---

## Step 3 — Calculate Target State Cost

Now model what happens if you add pre-commit and CI-stage security detection that catches 80% of defects before they reach QA:

Assumptions:
- Pre-commit tooling (Gitleaks, Semgrep) catches 60% of defects at cost of 1x
- CI pipeline tooling (SAST, SCA) catches an additional 20% of defects at cost of 3x
- Defects reaching QA/pentest/production reduced by 80%

Recalculate the table with these shifted detection rates and compare total monthly cost.

**Question:** What is the monthly savings? What is the annual ROI if the tooling costs $2,000/month in licensing and 20 hours/month of engineering time to maintain?

---

## Step 4 — Identify Your Three Highest-Impact Detection Improvements

Based on your cost model, identify the three changes to your detection pipeline that would produce the greatest cost reduction. For each:

1. What type of defect does it address? (secrets, vulnerable dependencies, code vulnerabilities, misconfigurations)
2. What is the earliest stage where this defect type can be detected automatically?
3. What tool would you use? (e.g., Gitleaks for secrets, Grype for dependencies, Semgrep for code)
4. What is the estimated monthly savings if 70% of these defects are caught at the earlier stage?

---

## Step 5 — Write a One-Paragraph Business Case

Using the numbers from Steps 2–4, write a one-paragraph business case for investing in earlier security detection. The paragraph should:

- State the current monthly cost of late detection (Step 2 total)
- State the projected monthly cost after improvements (Step 3 total)
- State the monthly savings and annual ROI
- Name the three specific improvements you would make

This paragraph should be usable as a slide in an executive presentation.

---

## Extension: Team Exercise

If completing this as a team exercise:

1. Have each team member independently estimate the hypothetical organization's defect distribution before comparing notes
2. Discuss where the largest disagreements are and why — what assumptions differ?
3. Identify one piece of data your organization does not currently collect that would make this model more precise
4. Agree on which detection improvement would have the highest ROI as a first investment

---

## Deliverable

A completed cost model (spreadsheet or table) and a one-paragraph business case as described in Step 5.
