# Chapter 3 — Kubernetes Hardening: Securing the Container Orchestration Layer

**Volume:** Book 3 — Cloud-Native Security for DevSecOps
**Framework reference:** [cloud-security-devsecops](../../../../cloud-security-devsecops/docs/architecture.md) | [cloud-security-devsecops: kubernetes-security.md](../../../../cloud-security-devsecops/docs/kubernetes-security.md)

---

## What You Will Learn

Kubernetes manages the execution environment for containerized workloads. A misconfigured Kubernetes cluster can expose the entire infrastructure: a compromised pod with host network access can reach the cloud provider's instance metadata service; a container running as root can escape to the host node; overly permissive RBAC can allow a workload to read secrets from other namespaces or even modify cluster configuration.

Kubernetes hardening is the process of configuring the control plane and workload admission policies to reduce the blast radius of any individual compromise.

This chapter covers:

1. **RBAC design** — structuring role bindings to prevent lateral movement within the cluster
2. **Pod Security Standards** — the built-in Kubernetes admission control framework for workload security
3. **Network policies** — namespace-level network segmentation to contain east-west traffic
4. **Secrets management** — why Kubernetes Secrets are not secrets, and what to use instead
5. **Admission controllers** — using Kyverno and OPA/Gatekeeper to enforce organizational policy at deployment time

---

## The Kubernetes Attack Surface

A Kubernetes cluster has several distinct attack surfaces, each requiring different hardening controls:

### The API Server

The Kubernetes API server is the control plane entry point. Every `kubectl` command, CI/CD deployment, and controller reconciliation loop goes through the API server. Unauthenticated or overly permissive access to the API server is catastrophic: it provides the ability to read secrets, create privileged pods, and modify workload configuration across the entire cluster.

Default hardening requirements:
- Disable anonymous authentication (`--anonymous-auth=false`)
- Enable Node and RBAC authorization modes
- Require client certificate authentication for system components
- Audit log all API server requests at the Metadata level or higher

Managed Kubernetes services (EKS, AKS, GKE) enforce most control plane hardening by default. The remaining hardening surface is in RBAC configuration and workload admission policies.

### Container Workloads

Container workloads run code provided by application teams, third-party dependencies, and base images. Security assumptions cannot be made about what a container will attempt to do. Pod security controls restrict what containers can do regardless of the code running inside them:

- Running as root creates privilege escalation paths to the host
- `hostNetwork: true` allows the container to access services bound to the node's network interfaces, including the cloud metadata service
- `hostPID: true` allows the container to see and send signals to all processes on the host
- Privileged mode (`securityContext.privileged: true`) grants the container full access to the host kernel

None of these capabilities should be permitted for application workloads.

### RBAC and Service Accounts

Every pod runs with a Kubernetes service account. By default, the service account token is auto-mounted into the pod at `/var/run/secrets/kubernetes.io/serviceaccount/token`. Any process inside the container can use this token to call the Kubernetes API.

If the service account has broad RBAC permissions, a compromised container has lateral movement capability within the cluster. An attacker who compromises a pod with `get secret` permissions across namespaces can read database passwords and API keys stored as Kubernetes Secrets.

### Kubernetes Secrets Are Base64-Encoded, Not Encrypted

The most frequently misunderstood Kubernetes security property: `Secret` objects are stored in etcd as base64-encoded values, not encrypted. Anyone with etcd access or `kubectl get secret` permissions can read them in plaintext.

Kubernetes Secrets should be used only for non-sensitive configuration where the Kubernetes RBAC layer provides sufficient access control. For genuinely sensitive values (database passwords, API keys, TLS private keys), use:
- **AWS Secrets Manager** with the AWS Secrets Store CSI driver
- **HashiCorp Vault** with the Vault Agent injector
- **Azure Key Vault** with the Azure Key Vault provider for Secret Store CSI

These systems provide encryption at rest, access audit logs, secret rotation, and RBAC that is independent of Kubernetes cluster access.

---

## RBAC Design for Least Privilege

### Principle: No ClusterRoleBindings for Application Workloads

ClusterRoleBindings apply permissions cluster-wide — across all namespaces. Application workloads should almost never need cluster-wide permissions. Use RoleBindings (namespace-scoped) instead.

### Principle: Disable Auto-Mounted Service Account Tokens

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: payment-processor
  namespace: payments
automountServiceAccountToken: false
```

Disable auto-mounting and explicitly mount tokens only in pods that need Kubernetes API access. Most application pods do not need to call the Kubernetes API.

### Principle: Explicit RBAC for Each Service

Each service should have a dedicated ServiceAccount with only the permissions it actually needs. Sharing ServiceAccounts between services means a compromise of one service exposes the RBAC permissions of all.

---

## Pod Security Standards

Kubernetes 1.25 introduced Pod Security Standards as the replacement for the deprecated PodSecurityPolicy. Three profiles are defined:

| Profile | Description | Use Case |
|---------|-------------|----------|
| `privileged` | No restrictions | Trusted system workloads (node agents, CNI plugins) |
| `baseline` | Prevents known privilege escalation | General workloads in dev/test |
| `restricted` | Hardened, follows current security best practices | Production application workloads |

Pod Security Standards are enforced at the namespace level via labels:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: payments
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/enforce-version: latest
    pod-security.kubernetes.io/warn: restricted
    pod-security.kubernetes.io/audit: restricted
```

With `enforce: restricted`, any pod that does not meet the restricted profile requirements is rejected at admission. The `warn` and `audit` labels provide non-blocking feedback and audit logging.

The `restricted` profile requires:
- `runAsNonRoot: true`
- `seccompProfile.type: RuntimeDefault` or `Localhost`
- No privilege escalation (`allowPrivilegeEscalation: false`)
- Drop all capabilities (`capabilities.drop: ["ALL"]`)
- No host path volumes, host network, host PID, or host IPC

---

## Network Policies

By default, Kubernetes allows unrestricted pod-to-pod communication within and across namespaces. Network policies allow specifying which pods can communicate with which other pods, using label selectors.

### Default Deny All

Start with a default-deny policy for each namespace and explicitly allow required traffic:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: payments
spec:
  podSelector: {}
  policyTypes:
    - Ingress
    - Egress
```

### Allow Specific Traffic

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-payments-api
  namespace: payments
spec:
  podSelector:
    matchLabels:
      app: payments-api
  policyTypes:
    - Ingress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: gateway
        - podSelector:
            matchLabels:
              app: api-gateway
      ports:
        - protocol: TCP
          port: 8080
```

Network policies are enforced by the Container Network Interface (CNI) plugin. Calico, Cilium, and Weave Net all support Kubernetes NetworkPolicy. The default CNI plugin in many managed clusters (aws-vpc-cni, Azure CNI) does not enforce network policies without additional configuration.

---

## Admission Controllers: Policy as Code

Pod Security Standards cover the security profile of individual pods. For organizational policy that goes beyond the built-in profiles, admission controllers enforce custom policy at deployment time.

### Kyverno

Kyverno uses Kubernetes-native YAML policies to validate, mutate, and generate resources:

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-labels
spec:
  validationFailureAction: Enforce
  rules:
    - name: require-team-label
      match:
        any:
          - resources:
              kinds:
                - Deployment
      validate:
        message: "Deployments must have a 'team' label"
        pattern:
          metadata:
            labels:
              team: "?*"
```

### OPA/Gatekeeper

OPA (Open Policy Agent) with Gatekeeper uses Rego policy language for more complex rules. Gatekeeper provides ConstraintTemplate CRDs that define policy rules, and Constraint resources that instantiate them.

Both tools are suited for enforcing:
- Required labels for all workloads
- Disallowed image registries (only allow images from approved registries)
- Resource limits required on all containers
- Required securityContext fields beyond what Pod Security Standards enforce

---

## Lab Exercise

The hands-on lab for this chapter covers:
1. Auditing a Kubernetes cluster configuration using kube-bench (CIS Benchmark)
2. Applying Pod Security Standard labels to a namespace and observing policy enforcement
3. Implementing default-deny network policies and selectively allowing service traffic
4. Replacing a Kubernetes Secret with AWS Secrets Manager via the Secrets Store CSI Driver
5. Writing and applying a Kyverno policy to enforce image registry restrictions

See [lab/README.md](lab/README.md) to begin.

---

## Key Controls Reference

| Control | Kubernetes Mechanism | Enforcement Point |
|---------|---------------------|-------------------|
| No privileged containers | Pod Security Standards: restricted | Namespace label |
| No root containers | `runAsNonRoot: true` | SecurityContext / Pod Security Standards |
| No auto-mounted tokens | `automountServiceAccountToken: false` | ServiceAccount |
| Network segmentation | NetworkPolicy | CNI plugin |
| Secrets encryption | External secrets store (Vault, AWS SM) | CSI driver |
| Image provenance | Kyverno / Gatekeeper + Cosign | Admission controller |
| Audit logging | API server audit policy | Control plane configuration |

---

## Further Reading

- [cloud-security-devsecops: kubernetes-security.md](../../../../cloud-security-devsecops/docs/kubernetes-security.md) — production Kubernetes security architecture
- [cloud-security-devsecops: architecture.md](../../../../cloud-security-devsecops/docs/architecture.md) — container and cluster security in the cloud security stack
- CIS Kubernetes Benchmark (`cisecurity.org`)
- Kubernetes Pod Security Standards (`kubernetes.io/docs/concepts/security/pod-security-standards/`)
- kube-bench: CIS Benchmark scanner for Kubernetes (`github.com/aquasecurity/kube-bench`)
