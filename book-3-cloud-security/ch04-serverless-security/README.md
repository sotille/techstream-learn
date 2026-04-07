# Chapter 4 — Serverless Security: Functions, Event Chains, and Ephemeral Execution

**Book:** Cloud-Native Security for DevSecOps (Volume 3)
**Chapter:** 4 of Book 3
**Framework reference:** cloud-security-devsecops/docs/serverless-security.md

---

## What You Will Learn

Serverless architectures shift the security model in ways that break traditional assumptions.
There is no server to harden, no persistent process to monitor at the OS layer, and no
long-lived network connection to inspect. What replaces these controls — and what new
attack surfaces appear — is the focus of this chapter.

By the end of this chapter, you will be able to:

- Identify the attack surface unique to serverless architectures (function code, event
  triggers, IAM permissions, and execution context)
- Apply least-privilege IAM to Lambda and Cloud Run functions, and explain why
  over-permissioned serverless functions are the most common serverless vulnerability
- Detect secrets, vulnerable dependencies, and logic flaws in function code before
  deployment using automated scanning
- Understand serverless-specific threats: event injection, excessive function permissions,
  function-to-function chaining risks, and cold-start timing attacks
- Configure runtime controls for serverless: VPC attachment, environment variable encryption,
  reserved concurrency, and execution time limits
- Map serverless security controls to CIS AWS Lambda Benchmark and relevant compliance
  frameworks

---

## Why Serverless Security Requires a Different Approach

In a traditional EC2 or Kubernetes environment, the security perimeter includes the OS,
the network interface, the container, and the runtime process. You can deploy host-based
intrusion detection (Falco, auditd), inspect system calls, and monitor persistent processes.
In a serverless environment, the cloud provider manages all of that. What remains under your
control is:

- **The function code** — including its dependencies
- **The IAM execution role** — what the function is allowed to do
- **The event trigger** — what data enters the function as input
- **The configuration** — environment variables, timeouts, concurrency, VPC attachment

This narrower control surface might sound simpler. In practice, it concentrates risk. A
single over-permissioned Lambda with unrestricted access to S3, DynamoDB, and SQS becomes
a lateral movement vehicle if its code is vulnerable to injection or its deployment is
compromised. The Uber breach of 2022 demonstrates that serverless and cloud function IAM
misconfigurations are among the most exploitable findings in modern cloud environments.

---

## The Serverless Threat Model

### Event Injection

Every serverless function receives input from an event trigger — an S3 object upload,
an API Gateway HTTP request, an SQS message, a DynamoDB stream. If the function
processes that input unsafely (SQL construction, shell execution, deserialization), it is
vulnerable to injection attacks regardless of whether it runs on Lambda or a VM.

Serverless changes the delivery mechanism for injection, not the vulnerability class.
An attacker who can write a malformed SQS message or upload a crafted S3 key can trigger
injection in a downstream Lambda that processes those events.

**Mitigation:** Input validation at the function boundary; treat all event data as untrusted
regardless of source; avoid constructing SQL, shell commands, or OS paths from event fields.

### Excessive Function Permissions

The most common serverless misconfiguration: attaching an IAM role with broad permissions
(S3 `*`, DynamoDB `*`, or full `AdministratorAccess`) because it is easier than scoping
permissions precisely. The consequences are asymmetric — any code execution path in the
function, including vulnerable dependencies, operates with those permissions.

A function that reads from one S3 prefix and writes to one DynamoDB table should have
exactly those four permissions (`s3:GetObject` on one ARN, `dynamodb:PutItem` on one ARN).
Every additional permission is attack surface.

**Mitigation:** Use IAM Access Analyzer to generate least-privilege policies from CloudTrail
logs; scope resource ARNs to the minimum required; never attach `AdministratorAccess` or
managed policies with wildcards.

### Dependency Vulnerabilities in Function Packages

Lambda deployment packages bundle their dependencies. Unlike containers with base images
updated by your platform team, Lambda packages are built by application teams and may not
be scanned. A vulnerable `log4j`, `requests`, or `axios` version in a Lambda ZIP file is
exploitable even if the rest of your container infrastructure is patched.

**Mitigation:** Run SCA (Grype, Trivy, npm audit) against function packages in CI; enforce
break-the-build on high-severity dependency vulnerabilities; use Lambda Layers for shared
dependencies to centralize patching.

### Function-to-Function Trust Assumptions

Serverless architectures often chain functions via event queues, API Gateway, or direct
invocations. Downstream functions may implicitly trust data from upstream functions.
If an upstream function is compromised or its output tampered with, the entire chain is
affected.

**Mitigation:** Validate input at every function boundary regardless of whether the source
is internal or external; sign event payloads where integrity is critical; apply
least-privilege IAM to every function-to-function invocation.

### Insecure Environment Variables

Secrets stored in Lambda environment variables are encrypted at rest (using the AWS-managed
key by default) but visible in plaintext to anyone with `lambda:GetFunction` permission.
This includes developers, CI/CD pipelines, and any IAM principal with broad Lambda access.
Secrets should be fetched from AWS Secrets Manager or Parameter Store at runtime, not
stored as Lambda environment variables.

**Mitigation:** Use Secrets Manager with runtime retrieval; encrypt environment variables
with a customer-managed KMS key at minimum; restrict `lambda:GetFunction` to principals
that require it.

---

## Key Serverless Security Controls

| Control | AWS Lambda | Google Cloud Run | Why It Matters |
|---------|-----------|-----------------|----------------|
| **Least-privilege execution role** | IAM role with minimum actions/resources | Service account with specific IAM bindings | Limits blast radius of code compromise |
| **VPC attachment** | Lambda VPC configuration | Cloud Run private VPC connector | Prevents exfiltration to arbitrary internet destinations |
| **KMS-encrypted environment variables** | CMK-based encryption | Secret Manager integration | Prevents secret exposure via `GetFunction` API |
| **Runtime SCA scanning** | Grype/Trivy in CI against ZIP package | Container scan in Cloud Build | Catches vulnerable dependencies before deployment |
| **Execution time limits** | Timeout configuration (max 15 min) | Max request timeout | Limits impact of DoS via slow events |
| **Reserved concurrency** | Reserved concurrency cap | Min/max instance configuration | Prevents a single function from consuming all account capacity |
| **Dead letter queue** | DLQ on async invocations | Pub/Sub dead-letter topics | Prevents silent data loss on function failure |
| **CloudTrail / Audit Logs** | Lambda API calls logged to CloudTrail | GCP Audit Logs | Enables investigation of unexpected invocations or IAM changes |

---

## CIS AWS Lambda Benchmark — Key Controls

The CIS AWS Lambda Benchmark provides a baseline for Lambda-specific hardening. Key checks
applicable to this chapter:

- **1.1** — Ensure Lambda functions have a least-privilege execution role (no wildcards in
  Action or Resource)
- **1.2** — Ensure Lambda functions are not publicly accessible (no resource-based policy
  granting `lambda:InvokeFunction` to `*`)
- **1.3** — Ensure Lambda environment variables do not contain credentials (checked by
  Checkov `CKV_AWS_45`)
- **2.1** — Ensure Lambda functions are deployed within a VPC
- **3.1** — Ensure Lambda function packages are scanned for known vulnerabilities before
  deployment

---

## Practical Tool Landscape

**Static analysis and SCA:**
- `checkov` — scans Lambda Terraform/CloudFormation for IAM and configuration misconfigurations
- `grype` — scans Lambda deployment packages (ZIP files) for vulnerable dependencies
- `semgrep` — detects injection vulnerabilities and insecure patterns in function code

**Runtime and monitoring:**
- AWS CloudTrail + GuardDuty — detects unusual Lambda invocation patterns and IAM credential
  use from Lambda execution roles
- AWS Lambda Insights — extended metrics for function performance and anomaly detection
- Datadog Lambda extension — APM, logging, and security monitoring without code changes

**Policy enforcement:**
- IAM Access Analyzer — generates least-privilege IAM policies from actual CloudTrail usage
- AWS Config rules (`lambda-function-public-access-prohibited`, `lambda-inside-vpc`) — detect
  Lambda misconfigurations in deployed state, not just IaC

---

## Compliance Alignment

Serverless security controls map to these framework requirements:

- **SOC 2 CC6.1** — Logical access controls (IAM least privilege, MFA for management)
- **PCI DSS 7.2** — Access controls based on business need (least-privilege IAM)
- **NIST CSF PR.AC-4** — Access permissions are managed (function execution role scoping)
- **CIS AWS Lambda Benchmark** — Sections 1 (Identity), 2 (Network), 3 (Code Quality)

---

## Hands-On Lab

**Lab:** Scanning and Hardening a Serverless Function Deployment
**Location:** `lab/README.md`
**Estimated time:** 45–60 minutes

In this lab you will scan a deliberately misconfigured Lambda Terraform module with Checkov,
identify IAM over-permissioning and secrets-in-environment-variables findings, then apply
the remediation patterns from this chapter. You will also run Grype against a Lambda
deployment package containing a vulnerable Python dependency to demonstrate SCA for
serverless functions.

---

## Further Reading

- cloud-security-devsecops/docs/serverless-security.md — Techstream serverless security reference
- cloud-security-devsecops/docs/zero-trust-architecture.md — Zero trust patterns for serverless event chains
- devsecops-framework/docs/runtime-threat-detection.md — Runtime detection techniques applicable to serverless
- [AWS Lambda Security Best Practices](https://docs.aws.amazon.com/lambda/latest/dg/lambda-security.html)
- [CIS AWS Lambda Benchmark](https://www.cisecurity.org/benchmark/amazon_web_services)
