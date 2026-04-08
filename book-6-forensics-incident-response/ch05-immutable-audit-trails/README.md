# Chapter 5 — Immutable Audit Trails

## What You Will Learn

This chapter covers the design and implementation of audit trail systems that remain trustworthy even when an attacker has compromised a pipeline component. You will learn the architectural patterns that produce tamper-evident logs, the tooling that enforces append-only writes, and the verification procedures that confirm audit trail integrity during an investigation.

## Why This Matters

Audit trails are only useful for forensics if they can be trusted. An attacker who compromises a CI runner or a build system may attempt to cover their tracks by deleting or modifying log entries. If your audit trail can be altered by an attacker who already has pipeline access, it provides no forensic value for exactly the incidents where you need it most.

Immutability is not a single property — it exists on a spectrum. A log written to a file on the same host as the compromised component offers no immutability guarantees. A log written over an authenticated, encrypted channel to an append-only external store with cryptographic signatures on each entry provides strong guarantees. Understanding the spectrum — and the cost/benefit of each point on it — is the core skill this chapter develops.

## Immutability Patterns

**Pattern 1 — Write-once object storage:** Pipeline events are written to object storage (S3, GCS, Azure Blob) with object lock (WORM) enabled. Once written, objects cannot be overwritten or deleted for the retention period. Cost: storage plus WORM licensing. Limitation: does not prevent a compromised writer from omitting events or writing false events.

**Pattern 2 — Append-only log service:** Events are sent to a dedicated append-only log service (CloudTrail with CloudTrail Lake, Azure Monitor immutable storage, Google Cloud Audit Logs). The service guarantees that entries cannot be retroactively modified or deleted. Limitation: log service itself is a trusted component; compromise of log service administrative credentials breaks the guarantee.

**Pattern 3 — Cryptographically signed log entries:** Each log entry is signed with a key held outside the pipeline environment. Verification confirms both that the entry was produced by an authorized publisher and that it has not been altered. Tools: Rekor (Sigstore), custom HSM-backed signing. Cost: key management infrastructure and verification workflow.

**Pattern 4 — Hash-chain integrity:** Each log entry includes the hash of the previous entry, forming a chain. Tampering with any entry invalidates all subsequent hashes. Provides detection of insertion, deletion, or modification. Used by: Certificate Transparency logs, some structured log formats.

## What You Will Practice

This chapter's lab covers two exercises:

**Exercise 1** — Configure a pipeline to emit structured audit events to a write-once S3 bucket with Object Lock, then verify the immutability guarantee by attempting to overwrite an entry.

**Exercise 2** — Evaluate a Rekor transparency log entry for a pipeline artifact. Verify the entry's signature, confirm the hash chain is intact, and describe what an investigator can conclude from the log entry during a forensic investigation.

## Lab

See [lab/README.md](lab/README.md) for the hands-on immutable audit trail exercises.
