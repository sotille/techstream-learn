# Lab 2 — Canary Releases: Progressive Delivery with Argo Rollouts

**Chapter:** 2 — Canary Releases
**Volume:** Book 4 — Release Engineering & DevSecOps Governance
**Estimated time:** 55–65 minutes
**Difficulty:** Intermediate
**Prerequisites:** `kubectl` + local Kubernetes cluster (minikube or kind), Helm 3, curl

---

## Objectives

By the end of this lab you will be able to:
- Install Argo Rollouts and the kubectl plugin
- Convert a standard Deployment to a Rollout with a canary strategy
- Trigger a canary deployment and observe traffic weight shifts
- Simulate a degraded canary and verify automatic rollback
- Configure an AnalysisTemplate with Prometheus-based quality gates

---

## Setup

### Start a Local Cluster

```bash
minikube start --kubernetes-version=v1.29.0
# or
kind create cluster --name canary-lab
```

### Install Argo Rollouts

```bash
kubectl create namespace argo-rollouts
kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argo-rollouts -n argo-rollouts --timeout=120s
```

### Install the kubectl Plugin

```bash
# macOS
brew install argoproj/tap/kubectl-argo-rollouts

# Linux
curl -LO https://github.com/argoproj/argo-rollouts/releases/latest/download/kubectl-argo-rollouts-linux-amd64
chmod +x kubectl-argo-rollouts-linux-amd64
sudo mv kubectl-argo-rollouts-linux-amd64 /usr/local/bin/kubectl-argo-rollouts
```

Verify:
```bash
kubectl argo rollouts version
```

### Install Prometheus (for Step 5)

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace \
  --set grafana.enabled=false \
  --set alertmanager.enabled=false
```

### Create the Lab Namespace

```bash
kubectl create namespace payments-lab
```

---

## Step 1 — Deploy the Stable Version

Deploy the initial stable version of the payment service:

```bash
kubectl apply -f examples/payment-service-rollout-v1.yaml -n payments-lab
kubectl apply -f examples/payment-service-svc.yaml -n payments-lab
kubectl argo rollouts get rollout payment-service -n payments-lab --watch
```

Wait until all 5 replicas are running and the rollout status shows `Healthy`.

```
Name:            payment-service
Namespace:       payments-lab
Status:          ✔ Healthy
Strategy:        Canary
  Step:          10/10
  SetWeight:     100
  ActualWeight:  100
```

---

## Step 2 — Trigger a Canary Deployment

Update the image to version v2, which simulates a new deployment:

```bash
kubectl argo rollouts set image payment-service \
  app=registry.internal.example.com/payment-service:v2 \
  -n payments-lab
```

Observe the rollout progression:

```bash
kubectl argo rollouts get rollout payment-service -n payments-lab --watch
```

Expected progression:
1. Rollout pauses at Step 1 (5% weight): `Paused`
2. Canary replica set is created with 1 pod
3. Status shows: `SetWeight: 5, ActualWeight: 5`

The rollout is paused at the first `pause: {}` step — it waits for manual promotion or analysis to complete.

**Promote to the next step:**

```bash
kubectl argo rollouts promote payment-service -n payments-lab
```

Observe the rollout advance to 25% weight, then 50%, then 100%.

---

## Step 3 — Simulate a Canary Failure

Reset to the stable version first:

```bash
kubectl argo rollouts undo payment-service -n payments-lab
kubectl argo rollouts get rollout payment-service -n payments-lab --watch
```

Wait until status shows `Healthy` again.

Now trigger a deployment of the `v3-degraded` image, which is configured to return 5xx errors at a 10% rate:

```bash
kubectl argo rollouts set image payment-service \
  app=registry.internal.example.com/payment-service:v3-degraded \
  -n payments-lab
```

Apply the analysis template and updated rollout that includes automatic failure detection:

```bash
kubectl apply -f examples/analysis-template-success-rate.yaml -n payments-lab
kubectl apply -f examples/payment-service-rollout-with-analysis.yaml -n payments-lab
```

Watch the rollout attempt the first canary step and run analysis:

```bash
kubectl argo rollouts get rollout payment-service -n payments-lab --watch
```

Because `v3-degraded` returns errors, the AnalysisRun will fail its success-rate check and trigger automatic rollback:

```
Name:            payment-service
Namespace:       payments-lab
Status:          ✖ Degraded
Message:         RolloutAborted: Rollout aborted update to revision 2:
                 metric "success-rate" assessed Failed due to failed (1) > failureLimit (0)
Strategy:        Canary
  Step:          0/10
  SetWeight:     0
  ActualWeight:  0
```

All traffic returns to the stable (v1) version automatically.

**Verify the rollback:**

```bash
kubectl argo rollouts get rollout payment-service -n payments-lab
kubectl get pods -n payments-lab -l app=payment-service
```

The canary pods should be terminating or terminated, and all traffic is on the stable replica set.

---

## Step 4 — Inspect the Analysis Run

After the failed rollout, examine the AnalysisRun that triggered the rollback:

```bash
kubectl get analysisrun -n payments-lab
kubectl describe analysisrun -n payments-lab
```

The output includes:
- The metric query that was evaluated
- The measured values at each interval
- The failure condition that triggered the abort

**Questions:**

1. How many measurement intervals ran before the analysis failed?
2. What was the measured success rate when the failure was triggered?
3. How long did it take from the canary becoming active to the rollback completing?
4. What notification channels would you configure to alert on-call when an AnalysisRun fails?

---

## Step 5 — Configure Prometheus-Based Quality Gates

The analysis template in `examples/analysis-template-success-rate.yaml` uses a placeholder Prometheus query. Update it to use the actual Prometheus instance installed in Step 0:

```bash
kubectl get svc -n monitoring | grep prometheus
```

Find the ClusterIP for the Prometheus service and update the `address` field in `examples/analysis-template-prometheus.yaml`:

```bash
kubectl apply -f examples/analysis-template-prometheus.yaml -n payments-lab
```

Generate test traffic to the payment service:

```bash
kubectl run traffic-generator --image=curlimages/curl --restart=Never -n payments-lab -- \
  sh -c 'while true; do curl -s http://payment-service.payments-lab.svc.cluster.local:8080/health > /dev/null; sleep 0.1; done'
```

Trigger a new deployment with the analysis enabled:

```bash
kubectl argo rollouts set image payment-service \
  app=registry.internal.example.com/payment-service:v2 \
  -n payments-lab
```

Watch the analysis run in real time:

```bash
kubectl argo rollouts get rollout payment-service -n payments-lab --watch
kubectl get analysisrun -n payments-lab -w
```

The canary should advance successfully through all steps when the v2 image has a low error rate.

---

## Step 6 — Reflect on Deployment Strategy Selection

Compare the blue-green deployment from Chapter 1 with the canary deployment in this lab:

| Property | Chapter 1 (Blue-Green) | This Lab (Canary) |
|----------|------------------------|-------------------|
| Initial user exposure | 100% after switch | 5% at first step |
| Rollback trigger | Manual (or monitoring alert) | Automatic (AnalysisRun) |
| Infrastructure during release | 2× capacity | ~1.05× at 5% canary |
| Validation basis | Staging environment tests | Live production traffic |
| Time to detect defect | After 100% exposure | After ~5% exposure |

**Write a deployment strategy decision framework for your organization:**

1. Which services should use canary (based on traffic volume, defect detectability, user sensitivity)?
2. Which services should use blue-green (based on rollback requirement, schema dependencies)?
3. What are your quality gate thresholds for advancing a canary (error rate, latency, business metric)?
4. What is the maximum canary duration before auto-promoting or auto-aborting if no analysis runs?

---

## Cleanup

```bash
kubectl delete namespace payments-lab argo-rollouts monitoring
minikube delete
# or
kind delete cluster --name canary-lab
```

---

## Deliverables

1. Screenshot or terminal output showing the automatic rollback triggered by the v3-degraded deployment
2. Answers to the four AnalysisRun inspection questions in Step 4
3. The Prometheus analysis template updated with the correct service address
4. The deployment strategy decision framework from Step 6

---

## References

- [Chapter 2 overview](../README.md)
- [Chapter 1: Blue-Green Deployments](../../ch01-blue-green-deployment/README.md)
- [release-orchestration-framework: progressive-delivery.md](../../../../../release-orchestration-framework/docs/progressive-delivery.md)
- Argo Rollouts documentation: `argo-rollouts.readthedocs.io`
- Argo Rollouts examples: `github.com/argoproj/argo-rollouts/tree/master/examples`
