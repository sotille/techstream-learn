# Chapter 1 — How Modern Pipelines Get Compromised

## What You Will Learn

CI/CD pipelines hold the keys to your organization's entire production environment. A single pipeline configuration file can expose cloud credentials, container registry access, deployment secrets, and production database connections — all to anyone who can influence what runs inside it. This chapter examines how adversaries think about and exploit CI/CD infrastructure.

By the end of this chapter, you will understand:

- Why CI/CD pipelines are a high-value attack target and how real-world attackers approach them
- The STRIDE threat modeling framework applied to pipeline security
- The six primary attack vectors used in documented CI/CD compromises
- How attack trees decompose complex attacks into addressable sub-problems
- Which controls address which attack paths — and how to prioritize your defenses

## Why It Matters

Three of the most significant supply chain attacks of the last decade — SolarWinds SUNBURST, the Codecov breach, and the PyTorch dependency confusion incident — all exploited CI/CD pipeline weaknesses. In each case, the attack surface was not the application itself, but the systems that build and deliver the application. Hardening application code while leaving the pipeline unprotected is equivalent to locking the front door and leaving the factory floor open.

Understanding how pipelines fail is prerequisite knowledge for designing pipelines that don't.

## Key Concepts

**Attack surface**: CI/CD pipelines hold credentials for every system they touch — source repositories, cloud accounts, container registries, deployment targets, and monitoring systems. This broad access makes them uniquely dangerous when compromised.

**The trust problem**: Pipelines execute code from multiple sources — your own application code, third-party actions, base container images, and package dependencies. Each of these is a potential injection point for malicious code.

**STRIDE for pipelines**: The STRIDE model (Spoofing, Tampering, Repudiation, Information Disclosure, Denial of Service, Elevation of Privilege) provides a structured vocabulary for naming and categorizing pipeline threats. Each STRIDE category maps to distinct attack vectors and corresponding mitigations.

**Attack trees**: A structured decomposition of an attacker's goal into the specific conditions that must be satisfied. Attack trees reveal that most high-impact attacks can be disrupted by blocking any one node in the tree — helping defenders prioritize controls with the highest coverage.

**Ephemeral build environments**: Build environments that are created fresh for each pipeline run and destroyed after completion. Ephemeral environments limit the blast radius of compromise, eliminate state accumulation between builds, and deny attackers persistence.

## Case Studies Covered

### SolarWinds SUNBURST (2020)
Nation-state attackers (attributed to Russia's SVR) compromised SolarWinds' Orion build environment and injected malicious code into the software update pipeline. Approximately 18,000 customers received the backdoored update before detection. The attackers had access to the build environment for months while evading detection by matching the behavior of legitimate build processes.

**Lesson:** Build environment integrity cannot be assumed — it must be continuously verified. The pipeline itself is threat surface.

### Codecov Breach (2021)
Attackers modified the Codecov Bash uploader script distributed from Codecov's official channel. The modified script exfiltrated environment variables — including cloud credentials, API tokens, and signing keys — from every CI environment running it. The modification persisted for approximately two months before discovery.

**Lesson:** Third-party CI tools require integrity verification at every use, not implicit trust in the distribution channel.

### PyTorch Dependency Confusion (2022)
A security researcher demonstrated a dependency confusion attack against PyTorch's nightly build pipeline by publishing a malicious package to PyPI with the same name as an internal PyTorch dependency. The malicious package was automatically installed during builds, achieving remote code execution in the PyTorch CI environment.

**Lesson:** Package manager resolution order creates an exploitable gap when internal package names are not reserved in public registries.

## Framework Reference

This chapter is based on the Secure CI/CD Reference Architecture:

- [Introduction — Threat Model and Attack Vectors](../../devsecops-framework/../secure-ci-cd-reference-architecture/docs/introduction.md)
- [Threat Model](../../secure-ci-cd-reference-architecture/docs/threat-model.md)

## Lab

See [lab/README.md](lab/README.md) for the hands-on exercise: **Threat Modeling Your CI/CD Pipeline with STRIDE**.
