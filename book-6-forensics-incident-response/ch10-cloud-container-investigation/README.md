# Chapter 10 — Cloud and Container Forensic Investigation

## What You Will Learn

This chapter covers the forensic investigation of incidents involving cloud infrastructure and container workloads. You will learn which evidence sources are available for terminated containers, how to reconstruct container execution history from control plane and data plane logs, how to investigate IAM and cloud API abuse, and how to work within the evidence constraints imposed by managed Kubernetes and serverless compute.

## Why This Matters

Cloud and container environments present forensic challenges that have no direct analog in traditional endpoint forensics. Containers may run for seconds before terminating; when they do, their filesystem is gone. Serverless functions run in shared, provider-managed environments where investigators have no access to the underlying host. IAM abuse can be conducted entirely through authenticated API calls that leave no process-level artifacts.

These constraints do not make investigation impossible — they make different evidence types primary. Investigators who understand which cloud evidence sources exist, where they are, and what they can and cannot prove are able to conduct effective investigations in these environments. Investigators who apply endpoint-centric forensics to cloud incidents consistently fail.

## Evidence Sources by Environment Type

**Kubernetes clusters:** Kubernetes API server audit log (records every API call with actor identity, verb, resource, and outcome), container runtime logs (containerd/cri-o, available until node is recycled), kubelet logs, admission webhook logs, image pull records. Key gap: container filesystem evidence is gone after pod termination unless a memory dump or filesystem snapshot was captured before deletion.

**Managed Kubernetes (EKS, GKE, AKS):** Cluster-level audit logs are available from the cloud provider. Node-level logs require node access or a DaemonSet log forwarder deployed in advance. Control plane events (node group scaling, cluster configuration changes) are in the cloud provider audit log.

**Container registries:** Image pull records, push history, tag mutation events, vulnerability scan results. Available in registry audit logs (ECR, GCR, ACR). Forensic value: establishes which image version was pulled and when, and whether an image tag was mutated after initial push.

**Cloud IAM:** CloudTrail (AWS), Cloud Audit Logs (GCP), Azure Activity Log — every API call made by every identity, with timestamps and request/response metadata. This is the primary evidence source for credential abuse investigations in cloud environments.

**Serverless (Lambda, Cloud Functions):** Function invocation records, execution logs, cold start metadata. No access to underlying host. Primary evidence: function logs (if shipped to a log aggregator before expiry), invocation records in cloud provider logs.

## What You Will Practice

This chapter's lab covers three investigation scenarios, each using a different evidence source:

**Scenario 1** — Kubernetes API server audit log analysis: given a 24-hour audit log extract, identify a sequence of API calls consistent with a compromised service account performing reconnaissance and attempting privilege escalation.

**Scenario 2** — Container registry mutation investigation: given registry audit logs and image digest records, determine whether an image tag was mutated after a known-good deployment and, if so, trace the identity that performed the mutation.

**Scenario 3** — Cloud IAM abuse: given CloudTrail logs from an AWS environment, trace the actions of a compromised OIDC federation token from the time of issuance through the actions taken before the token expired.

## Lab

See [lab/README.md](lab/README.md) for the guided cloud and container investigation exercises.
