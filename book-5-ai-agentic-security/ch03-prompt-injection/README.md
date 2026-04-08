# Chapter 3 — Prompt Injection: Direct, Indirect, and the DevSecOps Attack Surface

## What You Will Learn

This chapter distinguishes direct from indirect prompt injection and explains why indirect injection is the dominant threat in pipeline contexts. You will map prompt injection attack vectors across the five AI integration layers, understand why indirect injection is difficult to fully eliminate, and apply the layered defense controls that make pipeline AI components resilient to injection attempts.

## Why Indirect Injection Is the More Dangerous Threat

Direct prompt injection requires that an attacker have direct access to the AI component's input interface. In most enterprise DevSecOps pipelines, AI components are invoked by internal pipeline triggers, not exposed to external users. Direct injection is consequently uncommon in the pipeline threat model.

Indirect prompt injection exploits the fact that AI components read data from many sources as part of their normal operation: pull request descriptions, commit messages, code comments, CVE descriptions, issue titles, SBOM metadata, webhook payloads. An attacker who can write to any of these sources can embed adversarial instructions without ever interacting with the AI system directly.

The critical asymmetry: to inject indirectly, an attacker needs only the ability to write to data that the AI reads. In most organizations, external contributors can open pull requests. Public CVE databases can be read by AI triage tools. Package metadata can be crafted by package authors. The AI component's indirect attack surface is determined by which external data sources it reads — and that surface is often much larger than the organization realizes.

## The Injection Surface in a DevSecOps Pipeline

The injection surface spans every data source that AI pipeline components read:

**Source control:** PR titles and descriptions, commit messages, code comments, README files in scanned repositories, branch names, tag annotations.

**Issue and ticket systems:** Issue titles and bodies, comment threads, Jira descriptions, acceptance criteria fields in tickets read by AI components.

**External data feeds:** CVE descriptions from NVD, package metadata from npm/PyPI, SBOM component descriptions, container image labels, dependency advisory text.

**CI/CD inputs:** Test output piped to AI analysis tools, security scan output processed by triage agents, deployment log content read by AI monitoring components.

Any content that crosses a trust boundary and enters an AI component's context is a potential injection vector if the AI cannot reliably distinguish data from instructions.

## Defense in Depth Against Prompt Injection

No single control fully eliminates indirect injection risk. Defense requires layers:

**Input sanitization:** Strip or escape instruction-like patterns from untrusted data before it reaches the AI context. Effectiveness is imperfect — sanitization based on pattern matching can be bypassed by creative adversaries — but it raises the cost and complexity of injection attempts.

**Instruction hierarchy:** Place untrusted data in the `user` role, not the `system` role, in LLM API calls. Untrusted data should never be interpolated into the system prompt. Some models treat system-role instructions as higher-authority, which reduces the effectiveness of injections that arrive in user-role content.

**Output validation:** Validate AI component outputs against a schema or allowlist before acting on them. If the AI is supposed to return a structured JSON assessment, reject any output that doesn't conform to the schema. This catches injection attempts that cause the AI to produce unexpected output formats.

**Prompt canaries:** Embed a secret token in the system prompt that no legitimate AI output would include. If the canary appears in output or if the AI acknowledges the canary in its response, it signals possible injection or prompt extraction. Alert on canary appearances.

**Behavioral monitoring:** Establish baselines for AI component output patterns. Alert when outputs deviate significantly from the baseline — unusually short approvals, outputs that contain instruction-like language, changes in output schema compliance rate.

## What You Will Practice

This chapter's lab applies indirect prompt injection detection to a CI pipeline scenario. You will:

- Identify injection attempts embedded in a set of PR descriptions and commit messages
- Configure input sanitization that strips the most common injection patterns
- Design a canary-based detection approach for a specific AI pipeline component
- Evaluate which defenses would have detected and blocked the injections you identified

## Lab

See [lab/README.md](lab/README.md) for the hands-on exercise.

## Extended Reference

For deeper coverage of architectural defenses, structural instruction/data separation patterns, and output validation examples for specific AI pipeline task types, see the companion reference: [ch03-prompt-injection-defense/README.md](../ch03-prompt-injection-defense/README.md).
