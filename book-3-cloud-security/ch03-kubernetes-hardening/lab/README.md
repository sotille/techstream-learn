# Lab 3 — Kubernetes Hardening: CIS Benchmark, Pod Security, and Network Policies

**Chapter:** 3 — Kubernetes Hardening
**Volume:** Book 3 — Cloud-Native Security for DevSecOps
**Estimated time:** 55–70 minutes
**Difficulty:** Intermediate
**Prerequisites:** `kubectl` configured against a cluster (minikube, kind, or managed cluster), Docker, Helm 3

---

## Objectives

By the end of this lab you will be able to:
- Run kube-bench to identify CIS Benchmark violations in a Kubernetes cluster
- Apply and test Pod Security Standard enforcement in a namespace
- Implement default-deny network policies with selective allow rules
- Replace a Kubernetes Secret with a reference to an external secrets store
- Write a Kyverno admission policy and verify enforcement

---

## Setup

### Option A — Local Cluster (minikube)

```bash
minikube start --kubernetes-version=v1.29.0
kubectl cluster-info
```

### Option B — kind (Kubernetes in Docker)

```bash
kind create cluster --name hardening-lab
kubectl cluster-info --context kind-hardening-lab
```

Create the lab namespaces:

```bash
kubectl create namespace payments
kubectl create namespace gateway
kubectl create namespace kyverno-test
```

---

## Step 1 — CIS Benchmark Audit with kube-bench

kube-bench runs the CIS Kubernetes Benchmark checks against the cluster components. For managed clusters (EKS, AKS, GKE), only node-level checks are accessible; control plane checks require access to the control plane nodes.

### 1a — Run kube-bench as a Kubernetes Job

```bash
kubectl apply -f examples/kube-bench-job.yaml
kubectl wait --for=condition=complete job/kube-bench --timeout=120s
kubectl logs job/kube-bench | head -100
```

### 1b — Interpret Results

kube-bench output uses a scoring format:

```
[PASS] 1.1.1 Ensure that the API server pod specification file permissions are set to 600 or more restrictive
[FAIL] 1.2.1 Ensure that the --anonymous-auth argument is set to false
[WARN] 1.2.6 Ensure that the --kubelet-certificate-authority argument is set as appropriate
```

For each FAIL finding:
1. Note the CIS benchmark reference number
2. Note what the check tests
3. Identify whether it is a managed control plane control (cannot fix) or a node/workload control (can fix)

**Exercise:** From the kube-bench output, identify three FAIL findings that are within your control to remediate. For each, write the remediation step.

---

## Step 2 — Pod Security Standards Enforcement

### 2a — Apply Restricted Profile to the Payments Namespace

```bash
kubectl label namespace payments \
  pod-security.kubernetes.io/enforce=restricted \
  pod-security.kubernetes.io/enforce-version=latest \
  pod-security.kubernetes.io/warn=restricted \
  pod-security.kubernetes.io/audit=restricted
```

### 2b — Attempt to Deploy a Non-Compliant Pod

```bash
kubectl apply -f examples/pod-non-compliant.yaml -n payments
```

Expected output:
```
Error from server (Forbidden): error when creating "pod-non-compliant.yaml": pods "non-compliant-pod" is forbidden:
violates PodSecurity "restricted:latest":
  allowPrivilegeEscalation != false (container "app" must set securityContext.allowPrivilegeEscalation=false),
  unrestricted capabilities (container "app" must set securityContext.capabilities.drop=["ALL"]),
  runAsNonRoot != true (pod or container "app" must set securityContext.runAsNonRoot=true),
  seccompProfile (pod or container "app" must set securityContext.seccompProfile.type to "RuntimeDefault" or "Localhost")
```

The pod is rejected. Observe which specific security context fields are missing.

### 2c — Deploy a Compliant Pod

```bash
kubectl apply -f examples/pod-compliant.yaml -n payments
kubectl get pod payments-api -n payments
```

The compliant pod should deploy successfully.

### 2d — Verify the Security Context

```bash
kubectl describe pod payments-api -n payments | grep -A 20 "Security Context"
```

Confirm the security context includes:
- `allowPrivilegeEscalation: false`
- `capabilities.drop: [ALL]`
- `runAsNonRoot: true`
- `seccompProfile.type: RuntimeDefault`

---

## Step 3 — Network Policy: Default Deny and Selective Allow

### 3a — Verify Unrestricted Communication (Before)

Deploy a test pod and verify it can reach the payments namespace:

```bash
kubectl run test-pod --image=curlimages/curl --restart=Never -n gateway -- sleep 3600
kubectl apply -f examples/payments-api-service.yaml -n payments
kubectl exec -n gateway test-pod -- curl -s http://payments-api.payments.svc.cluster.local:8080/health
```

The request should succeed — no network policy is in place.

### 3b — Apply Default Deny All

```bash
kubectl apply -f examples/network-policy-default-deny.yaml -n payments
```

Retry the request:

```bash
kubectl exec -n gateway test-pod -- curl -s --max-time 5 http://payments-api.payments.svc.cluster.local:8080/health
```

Expected: request times out — the default deny policy blocks all ingress to the payments namespace.

### 3c — Apply Selective Allow for Gateway

```bash
kubectl apply -f examples/network-policy-allow-gateway.yaml -n payments
```

Retry the request from the gateway namespace:

```bash
kubectl exec -n gateway test-pod -- curl -s http://payments-api.payments.svc.cluster.local:8080/health
```

The request should succeed now — only traffic from pods labeled `app=api-gateway` in the `gateway` namespace is allowed.

### 3d — Verify Other Traffic Is Still Blocked

```bash
kubectl run test-pod-default --image=curlimages/curl --restart=Never -n default -- sleep 3600
kubectl exec -n default test-pod-default -- curl -s --max-time 5 http://payments-api.payments.svc.cluster.local:8080/health
```

Expected: timeout — traffic from the `default` namespace is still blocked.

---

## Step 4 — Replace Kubernetes Secrets with External References

### 4a — Observe the Problem: Kubernetes Secret is Base64-Encoded

Create a Kubernetes Secret and demonstrate it is not encrypted:

```bash
kubectl create secret generic db-credentials \
  --from-literal=password='sup3r-s3cr3t-passw0rd' \
  -n payments

kubectl get secret db-credentials -n payments -o jsonpath='{.data.password}' | base64 --decode
```

The password is readable by anyone with `kubectl get secret` permissions in the namespace — no decryption required.

### 4b — Examine the External Secrets Operator Pattern

Review `examples/external-secret.yaml`. This ExternalSecret resource references an AWS Secrets Manager secret:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: db-credentials
  namespace: payments
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-secrets-manager
    kind: ClusterSecretStore
  target:
    name: db-credentials
    creationPolicy: Owner
  data:
    - secretKey: password
      remoteRef:
        key: payments/prod/db-credentials
        property: password
```

The External Secrets Operator fetches the value from AWS Secrets Manager and creates a Kubernetes Secret. The Secrets Manager secret is encrypted at rest, access-controlled with IAM, and audited in CloudTrail. Rotation in Secrets Manager automatically refreshes the Kubernetes Secret on the next reconciliation interval.

**Key differences:**

| Property | Kubernetes Secret | AWS Secrets Manager + ESO |
|----------|------------------|-----------------------------|
| Encryption at rest | Optional (etcd encryption config required) | Always (AES-256) |
| Access audit log | Kubernetes audit log | CloudTrail |
| Rotation support | Manual | Automatic (Lambda rotator) |
| Cross-cluster sharing | Not supported | Supported |
| Emergency revocation | Delete secret + redeploy | Disable secret version |

### 4c — Write an IAM Policy for Secret Access

Write an IAM policy that grants a Kubernetes service account read-only access to secrets prefixed with `payments/prod/`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ReadPaymentsSecrets",
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Resource": "arn:aws:secretsmanager:us-east-1:123456789012:secret:payments/prod/*"
    }
  ]
}
```

Note that `secretsmanager:ListSecrets` is not included — the application needs the value, not the ability to enumerate what secrets exist.

---

## Step 5 — Kyverno Admission Policy: Image Registry Restrictions

### 5a — Install Kyverno

```bash
helm repo add kyverno https://kyverno.github.io/kyverno/
helm repo update
helm install kyverno kyverno/kyverno --namespace kyverno --create-namespace
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=kyverno -n kyverno --timeout=120s
```

### 5b — Apply the Registry Restriction Policy

```bash
kubectl apply -f examples/kyverno-registry-policy.yaml
```

This policy requires all container images to be pulled from `gcr.io/distroless` or your organization's internal registry (`registry.internal.example.com`).

### 5c — Test Policy Enforcement

Deploy a pod using an approved image:

```bash
kubectl run approved-pod \
  --image=gcr.io/distroless/static-debian11 \
  --restart=Never \
  -n kyverno-test
```

Deploy a pod using a disallowed image:

```bash
kubectl run unapproved-pod \
  --image=nginx:latest \
  --restart=Never \
  -n kyverno-test
```

Expected for the unapproved image:
```
Error from server: admission webhook "validate.kyverno.svc-fail" denied the request:
resource Pods/kyverno-test/unapproved-pod was blocked due to the following policies:
restrict-image-registries:
  validate-registries: "validation error: Images must be from approved registries.
  rule validate-registries failed at path /spec/containers/0/image/"
```

### 5d — Write an Additional Policy

Write a Kyverno ClusterPolicy that:
1. Validates that all Deployments in namespaces with `pod-security.kubernetes.io/enforce=restricted` have `resources.requests.memory` and `resources.requests.cpu` set on all containers
2. Uses `validationFailureAction: Enforce`

This ensures resource limits are always set — required for the HorizontalPodAutoscaler to function and for fair scheduling.

---

## Cleanup

```bash
minikube delete
# or
kind delete cluster --name hardening-lab
```

---

## Deliverables

1. Three CIS benchmark FAIL findings from kube-bench with remediation steps
2. The specific Pod Security Standard violations from the non-compliant pod attempt
3. A description of the network policy test results (before/after default deny, selective allow)
4. The IAM policy from Step 4c (completed)
5. The additional Kyverno policy from Step 5d

---

## References

- [Chapter 3 overview](../README.md)
- [cloud-security-devsecops: kubernetes-security.md](../../../../../cloud-security-devsecops/docs/kubernetes-security.md)
- kube-bench: `github.com/aquasecurity/kube-bench`
- CIS Kubernetes Benchmark: `cisecurity.org`
- Kyverno documentation: `kyverno.io`
- External Secrets Operator: `external-secrets.io`
