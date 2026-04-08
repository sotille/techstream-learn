# Chapter 1 — Why Standard IR Fails in Modern Pipelines

## What You Will Learn

This chapter establishes the foundational argument of the book: traditional incident response methodologies were designed for endpoint-centric environments and break down when applied to ephemeral, distributed, pipeline-driven systems. You will learn the specific structural gaps between standard IR and the evidence realities of container-based, cloud-native, and AI-augmented pipelines — and understand why forensic readiness must be designed in, not added after an incident occurs.

## Why This Matters

When a pipeline-level compromise occurs, responders applying standard IR playbooks frequently discover they lack the evidence needed to answer basic questions: What ran? When? With what authority? Standard IR assumes durable artifacts — disk images, memory dumps, persistent logs. Modern pipelines produce ephemeral artifacts that vanish when containers terminate, runners reset, and spot instances are reclaimed.

The consequence is not merely inconvenience. Without a forensic evidence trail, organizations cannot determine the scope of a compromise, cannot prove what an attacker did or did not access, and cannot satisfy legal or regulatory obligations for incident disclosure. They may spend weeks investigating an incident for which the primary evidence no longer exists.

This chapter catalogs those gaps systematically so the rest of the book can address them one by one.

## The Five Structural Gaps

**Gap 1 — Ephemeral compute:** Container-based pipeline runners and spot/preemptible cloud instances terminate after task completion. Standard IR requires access to the endpoint after the fact; ephemeral compute makes post-hoc access impossible unless evidence is externalized before termination.

**Gap 2 — Distributed event correlation:** A single pipeline execution touches a version control system, a build runner, an artifact registry, a deployment system, and a cloud provider — each with its own logging format, timestamp source, and retention policy. Standard IR correlates events from a manageable number of systems; distributed pipeline forensics requires correlating across six or more distinct event sources with no shared correlation identifier by default.

**Gap 3 — Supply chain opacity:** Modern pipelines pull code, dependencies, base images, and third-party actions from sources outside the organization's control. Standard IR assumes the organization can characterize all software running in the incident scope; supply chain opacity makes this assumption false.

**Gap 4 — Non-human identity proliferation:** Pipelines execute under machine identities — service accounts, IAM roles, deploy keys, OIDC federation tokens — that have no analog in endpoint-centric IR. Tracing what a compromised machine identity did requires evidence types (OIDC token claims, IAM CloudTrail events, deploy key audit logs) that are not present in standard IR toolkits.

**Gap 5 — AI component non-determinism:** AI-assisted pipeline components (code reviewers, test generators, deployment approval agents) may behave differently on identical inputs. Standard IR assumes deterministic software behavior; AI components break that assumption and require different evidence standards to establish what actually occurred versus what would normally occur.

## Key Vocabulary

- **Forensic readiness:** The degree to which an organization can collect, preserve, and produce admissible digital evidence with minimal post-incident effort.
- **Ephemeral artifact:** Any evidence source that ceases to exist after a time-limited event (container termination, runner reset, session expiry).
- **Chain of custody:** The documented, unbroken record of evidence possession, handling, and transfer from collection to presentation.
- **Correlation identifier:** A unique token (build ID, trace ID, request ID) that links events across multiple systems to a single pipeline execution.

## What You Will Practice

This chapter's lab is structured as a failure analysis exercise. You will be given a scenario in which an organization experienced a pipeline compromise and attempted to investigate using standard IR methods, and then:

- Identify which of the five structural gaps prevented successful investigation at each stage
- Propose the minimal forensic readiness controls that would have closed each gap
- Map each proposed control to the chapter of this book that covers its implementation

## Lab

See [lab/README.md](lab/README.md) for the hands-on failure analysis exercise.
