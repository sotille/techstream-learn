# Chapter 2 — Canary Releases: Gradual Traffic Shifting with Automated Rollback

**Volume:** Book 4 — Release Engineering & DevSecOps Governance
**Framework reference:** [release-orchestration-framework: progressive-delivery.md](../../../../release-orchestration-framework/docs/progressive-delivery.md) | [release-orchestration-framework: gitops-architecture.md](../../../../release-orchestration-framework/docs/gitops-architecture.md)

---

## What You Will Learn

Blue-green deployment (Chapter 1) provides instant rollback through traffic switching, but it commits 100% of users to the new version the moment the switch occurs. For high-traffic or high-risk services, that exposure is too large — if the new version has a subtle defect that only manifests under production load, all users are affected simultaneously.

Canary deployment solves this by routing a small fraction of traffic to the new version, measuring its behavior under real production load, and progressively expanding that fraction only when defined quality gates pass.

This chapter covers:

1. **Canary deployment mechanics** — how percentage-based traffic splitting works in Kubernetes
2. **Analysis and quality gates** — defining the metrics that determine whether a canary should advance or rollback
3. **Argo Rollouts** — the Kubernetes controller that orchestrates progressive delivery
4. **Rollback triggers** — configuring automatic rollback when error rates or latency thresholds are exceeded
5. **Header-based canary routing** — enabling internal teams to test against the canary without exposing external users

---

## The Problem with Full-Deployment Release

Deploying to 100% of users simultaneously creates a correlation between deployment risk and blast radius. A defect that affects 0.1% of requests affects 0.1% of all users immediately. For a service handling 10,000 requests per second, that is 10 error responses per second affecting real customers before monitoring can detect the problem and trigger a rollback.

Canary deployment decouples blast radius from the deployment event:
- **5% canary**: a defect affects only the 5% of users routed to the new version
- **Automated rollback**: if error rates exceed the threshold in the canary cohort, rollback occurs automatically before manual intervention
- **Staged expansion**: the canary only expands to 25%, then 50%, then 100% when quality gates pass at each stage

This pattern is standard practice at organizations with continuous deployment pipelines and strict uptime requirements. Netflix, Google, and Amazon use variants of this model for high-risk deployments.

---

## Traffic Splitting Models

### Weight-Based Splitting

The most common model: route a percentage of all traffic to the canary, with the remainder going to the stable version.

```
100% of traffic
    ├── 95% → Stable (v1.0)
    └──  5% → Canary  (v1.1)
```

Traffic distribution is approximate — load balancers distribute based on weights, not strict fractions. For statistical validity in metric analysis, the canary must handle enough requests to produce meaningful signal. At 5% of 10,000 RPS, the canary handles 500 RPS — sufficient for detecting error rates above 0.2% within minutes.

### Header-Based Splitting

Route specific requests to the canary based on HTTP headers. This allows internal teams, QA, or beta users to always hit the canary version:

```
X-Canary: true  →  Canary  (v1.1)
(no header)     →  Stable  (v1.0)
```

Header-based routing enables testing under production conditions without any user exposure. It is typically combined with weight-based splitting: internal traffic uses the header, production traffic uses weights.

### Cookie-Based Splitting

Route requests based on a cookie value — useful for ensuring consistent user experience during testing. Once a user is assigned to the canary cohort via a cookie, all their subsequent requests go to the same version.

---

## Quality Gates: Defining Success Criteria

A canary without quality gates is just a slow deployment. The value of progressive delivery comes from measurable gates that determine advancement or rollback.

### Metric Categories

| Category | What to Measure | Example Threshold |
|----------|----------------|-------------------|
| **Error rate** | HTTP 5xx rate vs. baseline | Canary error rate ≤ 1.5× baseline |
| **Latency** | p99 response time | p99 canary latency ≤ 110% of baseline p99 |
| **Success rate** | HTTP 2xx rate | Success rate ≥ 99.5% |
| **Custom business metric** | Add-to-cart rate, transaction success | Canary metric ≥ 95% of baseline |

### Analysis Providers

Quality gate metrics are fetched from observability platforms:
- **Prometheus** — self-hosted metrics, custom application metrics
- **Datadog** — managed APM, infrastructure metrics, custom dashboards
- **New Relic** — APM traces, error rates, user-facing performance
- **CloudWatch** — AWS-native metrics, Lambda, ALB error rates

Argo Rollouts supports all of these as AnalysisTemplate providers.

---

## Argo Rollouts: Progressive Delivery Controller

Argo Rollouts extends the Kubernetes Deployment abstraction with a `Rollout` custom resource that adds progressive delivery strategies (canary, blue-green) and metric analysis.

### Rollout Resource (Canary Strategy)

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: payment-service
  namespace: payments
spec:
  replicas: 10
  selector:
    matchLabels:
      app: payment-service
  template:
    metadata:
      labels:
        app: payment-service
    spec:
      containers:
        - name: app
          image: registry.internal.example.com/payment-service:v1.1
  strategy:
    canary:
      steps:
        - setWeight: 5       # Route 5% of traffic to canary
        - pause: {}          # Pause until analysis passes or timeout
        - analysis:
            templates:
              - templateName: success-rate-analysis
        - setWeight: 25
        - pause: {duration: 10m}
        - analysis:
            templates:
              - templateName: success-rate-analysis
        - setWeight: 50
        - pause: {duration: 10m}
        - analysis:
            templates:
              - templateName: success-rate-analysis
```

### AnalysisTemplate Resource

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AnalysisTemplate
metadata:
  name: success-rate-analysis
  namespace: payments
spec:
  args:
    - name: service-name
  metrics:
    - name: success-rate
      interval: 1m
      count: 5
      successCondition: result[0] >= 0.99
      failureLimit: 1
      provider:
        prometheus:
          address: http://prometheus.monitoring.svc.cluster.local:9090
          query: |
            sum(rate(http_requests_total{
              service="{{args.service-name}}",
              status=~"2.."
            }[1m])) /
            sum(rate(http_requests_total{
              service="{{args.service-name}}"
            }[1m]))
```

The analysis runs 5 measurements at 1-minute intervals. If the success rate drops below 99% in any measurement (`failureLimit: 1`), the rollout is marked as failed and automatic rollback begins.

---

## Automatic Rollback

When an AnalysisRun fails, Argo Rollouts automatically:
1. Shifts all traffic back to the stable version (setWeight: 0 for canary)
2. Scales down the canary replica set
3. Records the failure reason in the Rollout status
4. Sends a notification (configurable: Slack, webhook, email)

The rollback is complete within one reconciliation cycle (typically 10–30 seconds). This is significantly faster than manual detection and intervention, and it happens without human action.

---

## Canary vs. Blue-Green: Decision Framework

| Criterion | Blue-Green | Canary |
|-----------|-----------|--------|
| Rollback time | Seconds (traffic switch) | Seconds (weight to 0) |
| Blast radius | 100% immediately | Configurable (start at 1–5%) |
| Metric validation | Pre-switch (staging) | Live production traffic |
| Infrastructure cost | 2× capacity during release | Proportional to canary weight |
| Complexity | Medium | High |
| Best for | Critical systems requiring zero rollback time | High-traffic services requiring production validation |

For most application services, canary provides better risk management. For payment processing, financial ledgers, or schema migrations that cannot run both versions simultaneously, blue-green is preferred.

---

## Lab Exercise

The hands-on lab for this chapter covers:
1. Installing Argo Rollouts in a local Kubernetes cluster
2. Converting a Deployment to a Rollout with a canary strategy
3. Triggering a canary deployment and observing traffic distribution
4. Simulating a degraded canary (injecting errors) and watching automatic rollback
5. Configuring an AnalysisTemplate with Prometheus success-rate metrics

See [lab/README.md](lab/README.md) to begin.

---

## Key Concepts

| Concept | Definition |
|---------|------------|
| Canary | A small fraction of traffic routed to a new version before full promotion |
| AnalysisTemplate | Kubernetes resource defining quality gate metrics and thresholds |
| AnalysisRun | Execution instance of an AnalysisTemplate during a rollout |
| Progressive delivery | Release strategy using incremental traffic shifting with automated gate evaluation |
| Stable ReplicaSet | The current production version maintained by Argo Rollouts |
| Canary ReplicaSet | The new version receiving the canary traffic percentage |
| Weighted traffic | Load balancer routing based on percentage weights between stable and canary |

---

## Further Reading

- [release-orchestration-framework: progressive-delivery.md](../../../../release-orchestration-framework/docs/progressive-delivery.md) — canary, blue-green, and feature flags patterns
- [release-orchestration-framework: gitops-architecture.md](../../../../release-orchestration-framework/docs/gitops-architecture.md) — GitOps delivery model for automated progressive delivery
- Argo Rollouts documentation: `argo-rollouts.readthedocs.io`
- [Chapter 1: Blue-Green Deployments](../ch01-blue-green-deployment/README.md) — prerequisite reading
