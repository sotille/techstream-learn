# Business Case Template — Investing in Earlier Security Detection

Use this template to draft the one-paragraph business case described in Lab Step 5.
Fill in the bracketed values from your completed cost model.

---

## One-Paragraph Business Case (Executive Presentation Format)

Our organization currently spends an estimated **$[CURRENT_MONTHLY_COST]/month**
on security defect remediation — the majority attributable to defects discovered
at [HIGHEST_COST_STAGE] or later, where each defect costs an average of
[HIGHEST_MULTIPLIER]x more to fix than if caught at commit time.
By deploying [TOOL_1] for [DEFECT_TYPE_1], [TOOL_2] for [DEFECT_TYPE_2], and
[TOOL_3] for [DEFECT_TYPE_3] — shifting an estimated 80% of current defects to
pre-commit or CI-stage detection — we project monthly remediation costs will
fall to **$[TARGET_MONTHLY_COST]/month**, a reduction of
**$[MONTHLY_SAVINGS]/month ($[ANNUAL_SAVINGS]/year)**.
At a fully-loaded tooling and maintenance cost of **$[TOOLING_COST]/month**,
this investment yields a net annual return of **$[NET_ROI]**, with measurable
improvement in Mean Time to Detect (MTTD) and Mean Time to Remediate (MTTR)
within the first 90 days of deployment.

---

## Example (Filled In — Hypothetical 200-Person Organization)

Our organization currently spends an estimated **$108,000/month** on security
defect remediation — the majority attributable to defects discovered during
penetration testing ($48,000/month) or reaching production ($36,000/month),
where each defect costs 40–100x more to fix than if caught at commit time.
By deploying Gitleaks for secrets detection, Grype/Trivy for dependency
vulnerabilities, and Semgrep for code-level security issues — shifting an
estimated 80% of current defects to pre-commit or CI-stage detection — we project
monthly remediation costs will fall to **$24,336/month**, a reduction of
**$83,664/month ($1,003,968/year)**.
At a fully-loaded tooling and maintenance cost of **$4,400/month** (licensing
plus 20 hours of engineering time), this investment yields a net annual return
of **$951,168**, with measurable improvement in MTTD and MTTR
within the first 90 days of deployment.

---

## Supporting Data (Attach to Presentation)

- Current state cost model: `defect-cost-model-template.csv`
- Target state projection: `defect-cost-model-target-state.csv`
- Defect cost amplification research: Capers Jones, "Applied Software Measurement" (2008)
- DORA metrics baseline: https://dora.dev/research/
