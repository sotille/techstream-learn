# Lab 1 — Threat Modeling Your CI/CD Pipeline with STRIDE

**Estimated time:** 45–60 minutes
**Difficulty:** Beginner
**Prerequisites:** Access to a CI/CD pipeline configuration file (GitHub Actions, GitLab CI, or Jenkins). You can use the example file in `examples/` if you do not have your own.

---

## Objective

Apply the STRIDE threat model to a real (or example) CI/CD pipeline configuration. By the end of this lab, you will have a completed threat model for a pipeline with at least 12 identified threats, each mapped to a concrete mitigation.

---

## Background

STRIDE is a threat modeling methodology developed at Microsoft. Each letter represents a threat category:

| Letter | Threat | What it means for pipelines |
|--------|--------|----------------------------|
| **S** | Spoofing | Impersonating a developer, service account, or trusted component |
| **T** | Tampering | Modifying source code, pipeline config, dependencies, or artifacts |
| **R** | Repudiation | Performing actions without attribution (unsigned commits, missing logs) |
| **I** | Information Disclosure | Leaking secrets, source code, or sensitive build data |
| **D** | Denial of Service | Disrupting the pipeline, blocking deployments |
| **E** | Elevation of Privilege | Gaining permissions beyond what was authorized |

---

## Step 1 — Inventory Your Pipeline's Trust Boundaries

A trust boundary is any point where data, code, or credentials cross from one trust zone to another. Common pipeline trust boundaries:

1. **Developer workstation → Source repository** (code commit)
2. **Source repository → CI platform** (pipeline trigger)
3. **CI platform → Package registries** (dependency resolution)
4. **CI platform → Artifact registry** (image push)
5. **CI platform → Cloud provider** (deployment credentials)
6. **CI platform → Third-party actions/plugins** (code execution)

**Exercise:** Open the example pipeline file at `examples/github-actions-pipeline.yml`. Identify and list all trust boundaries present in this pipeline. Write them down before continuing.

---

## Step 2 — Apply STRIDE to Each Trust Boundary

For each trust boundary you identified, work through all six STRIDE categories. Ask: "What could go wrong here?" Use this template for each threat you identify:

```
Threat ID: [BOUNDARY]-[STRIDE-LETTER]-[NUMBER]
Trust Boundary: [e.g., CI platform → Package registries]
Threat Category: [Spoofing / Tampering / Repudiation / Information Disclosure / DoS / Elevation of Privilege]
Threat Description: [What could an attacker do?]
Attack Path: [How would they do it?]
Impact: [What is the consequence if this threat is realized?]
Mitigation: [What control prevents or detects this?]
Current Status: [Implemented / Partially implemented / Not implemented]
```

**Minimum target:** 12 threats across all six STRIDE categories.

---

## Step 3 — Prioritize by Impact × Likelihood

Score each threat on two dimensions:

- **Impact** (1–5): 1 = minor disruption, 5 = production compromise or data breach
- **Likelihood** (1–5): 1 = requires nation-state capability, 5 = exploitable by script kiddie

Calculate a risk score: `Impact × Likelihood`. Sort your threat list by score, descending.

---

## Step 4 — Identify the Top 3 Unmitigated Threats

From your sorted list, identify the three highest-risk threats that are **not currently mitigated** in the example pipeline. For each:

1. Describe the concrete attack scenario
2. Identify the specific pipeline configuration change that would mitigate it
3. Estimate the implementation effort (hours)

---

## Step 5 — Validate Against the Attack Trees

Compare your threat list against the two attack trees in [Chapter 1](../README.md):

- Attack Tree 1: Inject malicious code into a production artifact
- Attack Tree 2: Exfiltrate secrets from CI/CD pipeline

For each leaf node in the attack trees, verify that your threat model includes a corresponding threat. If you missed any, add them now.

---

## Deliverable

A completed threat model document containing:
- List of trust boundaries (minimum 5)
- At least 12 STRIDE threats with mitigations
- Risk-sorted threat list
- Top 3 unmitigated threats with proposed mitigations
- Coverage check against the two attack trees

---

## Example Output (Partial)

```
Threat ID: REG-T-01
Trust Boundary: CI platform → Package registries
Threat Category: Tampering
Threat Description: Attacker publishes a malicious package to a public registry with the same
  name as an internal package, exploiting dependency resolution order (dependency confusion).
Attack Path: Attacker discovers internal package name from job listings or error messages.
  Publishes higher-versioned package to PyPI/npm. Package manager resolves to public package.
Impact: 5 — malicious code executes in CI environment with full pipeline credentials
Likelihood: 3 — requires knowledge of internal package names; publicly documented technique
Risk Score: 15
Mitigation: Configure package manager to use private registry exclusively for known internal
  package scopes; disable fallback to public registry for internal namespaces.
Current Status: Not implemented (example pipeline uses default pip/npm resolution)
```

---

## Extension Exercise

If time permits, apply the same threat model to your own organization's CI/CD pipeline. Focus on:

1. What trust boundaries are present that are not present in the example?
2. Are any high-risk threats in your model not mitigated by current controls?
3. What would the priority order for remediation be?
