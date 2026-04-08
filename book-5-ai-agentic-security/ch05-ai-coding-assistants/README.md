# Chapter 5 — AI Coding Assistants: Slopsquatting, Hallucinated Packages, and Secret Exfiltration

## What You Will Learn

This chapter examines the security risks that AI coding assistants introduce at the developer workstation — the layer of the AI integration surface where the developer interacts directly with AI tools to write, review, and debug code. You will learn to identify and prevent the three primary threats at this layer: slopsquatting (AI-hallucinated package names that can be exploited by adversaries), credential and secret exfiltration through AI assistant context transmission, and the organizational risks of unvetted AI tool adoption.

## Why This Matters

Chapter 1 introduced slopsquatting as a documented attack pattern. This chapter goes deeper: the mechanics of how slopsquatting progresses from AI suggestion to supply chain compromise, the controls that interrupt it at each stage, and the organizational policies required to prevent credential exposure through AI assistant integrations.

The threat profile at the developer workstation layer is qualitatively different from CI/CD threats:

- **No pipeline controls apply.** Code that never reaches a CI/CD pipeline can still be affected by slopsquatting — a developer who installs a hallucinated package locally and tests code against it before committing may introduce a compromised dependency that passes initial development review.
- **Data at rest is exposed.** An AI assistant that processes an open IDE window can access `.env` files, private keys in `~/.ssh`, database connection strings in config files — all of which are present on the developer's workstation but would never be committed to version control.
- **Trust in AI suggestions is high.** Developers working under time pressure accept AI suggestions without verifying them. The slopsquatting attack works because the package name looks plausible.

## Key Concepts

### Slopsquatting: From Hallucination to Compromise

The slopsquatting attack chain has four stages:

**Stage 1 — Hallucination:** An AI coding assistant generates a code suggestion that includes a package import or dependency that does not exist in the target package registry. The hallucinated name is typically plausible: it sounds like a real package and is consistent with the code context.

**Stage 2 — Registration:** The adversary monitors AI-generated code (through public GitHub commits, code sharing platforms, or large-scale scanning of publicly visible AI outputs) to identify hallucinated package names that have not yet been registered. The adversary registers the package name with a malicious payload.

**Stage 3 — Installation:** The developer runs `pip install`, `npm install`, or equivalent. The package manager resolves the hallucinated name to the adversary's registered package and installs it.

**Stage 4 — Execution:** The malicious package executes at install time (using setup.py, postinstall hooks, or similar mechanisms), exfiltrating credentials, establishing persistence, or preparing for later stages of a supply chain attack.

The window between Stage 1 and Stage 2 may be weeks or months. Developers who accept AI suggestions today may have installed packages that are registered as malicious by the time they run the install command.

### Organizational AI Usage Policy: What It Must Cover

An organizational AI usage policy for developers is not a blanket "AI is approved" or "AI is banned." It must address:

1. **Which tools are approved** and under what conditions
2. **Data classification rules** — what code and data may be sent to external AI providers
3. **Dependency review requirements** — AI-generated dependency names must be verified
4. **Secret handling rules** — credential files must be excluded from AI context
5. **Incident reporting** — how to report a suspected credential exposure through AI

The policy without enforcement is not a control. Enforcement mechanisms include pre-commit hooks, network egress controls, and MDM-managed plugin lists.

### Network Egress and Data Transmission Controls

AI coding assistant plugins in IDEs establish outbound network connections to model provider APIs. The data transmitted typically includes:

- The current file being edited
- Recently opened files
- Selected text or the surrounding code context
- In some tools: the full codebase index or workspace contents

Organizations can control this transmission through:
- Network allowlisting at the firewall (block unapproved AI provider endpoints)
- Privacy mode configuration for approved tools (reduce transmission scope)
- Local LLM deployment (no external transmission)
- AI context exclusion configuration (`.copilotignore`, per-tool exclusion settings)

## What You Will Practice

This chapter's lab has two exercises:

**Exercise 1 — Slopsquatting detection and prevention**

You will examine a realistic set of AI-generated code snippets across Python, JavaScript, and Go. Each snippet contains one or more dependency references. Your task:
- Identify which dependency names exhibit slopsquatting characteristics (plausible but non-existent, recently registered, or inconsistent with known package ecosystems)
- Configure and test a pre-commit hook that verifies dependency existence against a simulated private registry mirror
- Trace the attack chain for one slopsquatting example: how would this package reach production, and at what stage would the controls you configured intercept it?

**Exercise 2 — AI assistant data policy implementation**

You will be given a repository that contains mixed-classification content: general application code, infrastructure configuration, test data, and credential files. Your task:
- Classify each file or directory according to a provided data classification policy
- Configure the appropriate AI context exclusion files (`.copilotignore` and equivalent) so that restricted and confidential files are excluded from AI assistant transmission
- Verify that your configuration is correct by reviewing what a simulated AI assistant context capture would include

## Lab

See [lab/README.md](lab/README.md) for the hands-on exercises.
