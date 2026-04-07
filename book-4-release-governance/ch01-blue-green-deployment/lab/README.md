# Lab 1 — Implementing Blue-Green Deployment with Traffic Switching in Kubernetes

**Estimated time:** 45–60 minutes
**Difficulty:** Intermediate
**Prerequisites:**
- `kubectl` installed and configured
- A local Kubernetes cluster (minikube, kind, or Docker Desktop Kubernetes)
- `curl` for smoke testing
- Basic familiarity with Kubernetes Deployments and Services

---

## Setup: Start a Local Cluster

```bash
# Using minikube
minikube start --cpus 2 --memory 2048

# Or using kind
kind create cluster --name blue-green-lab

# Verify cluster is running
kubectl cluster-info
kubectl get nodes
```

---

## Part 1: Deploy Blue Version (v1.0)

We use a simple NGINX-based application to simulate two versions of a service. The "blue" version returns version 1.0 content; the "green" version returns version 1.1.

### Step 1 — Create the Blue Deployment

Save as `blue-deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp-blue
  labels:
    app: webapp
    version: blue
spec:
  replicas: 3
  selector:
    matchLabels:
      app: webapp
      version: blue
  template:
    metadata:
      labels:
        app: webapp
        version: blue
    spec:
      containers:
        - name: webapp
          image: nginx:1.27-alpine
          ports:
            - containerPort: 80
          resources:
            requests:
              cpu: "50m"
              memory: "64Mi"
            limits:
              cpu: "100m"
              memory: "128Mi"
          readinessProbe:
            httpGet:
              path: /healthz
              port: 80
            initialDelaySeconds: 5
            periodSeconds: 5
          livenessProbe:
            httpGet:
              path: /healthz
              port: 80
            initialDelaySeconds: 10
            periodSeconds: 10
          volumeMounts:
            - name: content
              mountPath: /usr/share/nginx/html
      volumes:
        - name: content
          configMap:
            name: webapp-blue-content
```

Create the ConfigMap with version-identifying content:

```bash
kubectl create configmap webapp-blue-content \
  --from-literal=index.html='<html><body><h1>webapp v1.0 (blue)</h1></body></html>' \
  --from-literal=healthz='OK'
```

Apply the deployment:

```bash
kubectl apply -f blue-deployment.yaml
kubectl rollout status deployment/webapp-blue
```

### Step 2 — Create the Service Pointing to Blue

Save as `webapp-service.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: webapp
  labels:
    app: webapp
spec:
  selector:
    app: webapp
    version: blue    # ← This is the traffic switch control
  ports:
    - port: 80
      targetPort: 80
      protocol: TCP
  type: ClusterIP
```

```bash
kubectl apply -f webapp-service.yaml
kubectl get service webapp
```

### Step 3 — Verify Blue Version Is Serving Traffic

```bash
# Open a port-forward to test
kubectl port-forward service/webapp 8080:80 &
PORT_FORWARD_PID=$!

# Test the service
curl -s http://localhost:8080/
# Expected: webapp v1.0 (blue)

curl -s http://localhost:8080/healthz
# Expected: OK

kill $PORT_FORWARD_PID
```

---

## Part 2: Deploy Green Version (v1.1) Without Disruption

Deploy v1.1 (green) without changing the Service selector. At this point, zero traffic goes to green — we are simply preparing the new version.

### Step 4 — Create the Green Deployment

```bash
kubectl create configmap webapp-green-content \
  --from-literal=index.html='<html><body><h1>webapp v1.1 (green)</h1><p>New feature: improved response time</p></body></html>' \
  --from-literal=healthz='OK'
```

Save as `green-deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp-green
  labels:
    app: webapp
    version: green
spec:
  replicas: 3
  selector:
    matchLabels:
      app: webapp
      version: green
  template:
    metadata:
      labels:
        app: webapp
        version: green
    spec:
      containers:
        - name: webapp
          image: nginx:1.27-alpine
          ports:
            - containerPort: 80
          resources:
            requests:
              cpu: "50m"
              memory: "64Mi"
            limits:
              cpu: "100m"
              memory: "128Mi"
          readinessProbe:
            httpGet:
              path: /healthz
              port: 80
            initialDelaySeconds: 5
            periodSeconds: 5
          volumeMounts:
            - name: content
              mountPath: /usr/share/nginx/html
      volumes:
        - name: content
          configMap:
            name: webapp-green-content
```

```bash
kubectl apply -f green-deployment.yaml
kubectl rollout status deployment/webapp-green
```

**Key observation:** While this deployment is running, verify that the Service still routes to blue:

```bash
kubectl port-forward service/webapp 8080:80 &
curl -s http://localhost:8080/
# Still shows: webapp v1.0 (blue)
kill %1
```

Green is deployed and ready, but receives zero traffic. This is the pre-switch state.

---

## Part 3: Run Smoke Tests Against Green (Pre-Switch)

Before switching traffic, verify green passes all required health checks. In production, this would run against a staging ingress or a port-forward to the green deployment directly.

```bash
# Test green directly (bypassing the service, using pod label selector)
kubectl port-forward deployment/webapp-green 8081:80 &

# Health check
HEALTH=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8081/healthz)
echo "Green health check HTTP status: ${HEALTH}"
[ "${HEALTH}" = "200" ] && echo "PASS: Health check" || echo "FAIL: Health check"

# Content check — verify v1.1 is serving
CONTENT=$(curl -s http://localhost:8081/)
echo "${CONTENT}" | grep -q "v1.1" && echo "PASS: Version check" || echo "FAIL: Version check"

kill %1
echo "Smoke tests complete. Ready for traffic switch."
```

---

## Part 4: Atomic Traffic Switch to Green

The traffic switch is a single command — patching the Service selector to point to green:

```bash
# Record the current state before switching (for rollback)
CURRENT_VERSION=$(kubectl get service webapp -o jsonpath='{.spec.selector.version}')
echo "Current active version: ${CURRENT_VERSION}"

# Perform the traffic switch
kubectl patch service webapp \
  -p '{"spec":{"selector":{"version":"green"}}}'

# Verify the switch
ACTIVE_VERSION=$(kubectl get service webapp -o jsonpath='{.spec.selector.version}')
echo "Active version after switch: ${ACTIVE_VERSION}"

# Confirm traffic is now going to green
kubectl port-forward service/webapp 8080:80 &
curl -s http://localhost:8080/
# Expected: webapp v1.1 (green)
kill %1
```

**Measure the switch time.** The `kubectl patch` command completes in under a second. The service selector change is immediately effective — there is no gradual rollout, no pod restart. Existing connections complete on blue pods, new connections go to green.

---

## Part 5: Rollback — Switch Back to Blue

If monitoring detects a problem after the switch:

```bash
# Rollback: switch selector back to blue
kubectl patch service webapp \
  -p '{"spec":{"selector":{"version":"blue"}}}'

# Verify rollback
kubectl port-forward service/webapp 8080:80 &
curl -s http://localhost:8080/
# Expected: webapp v1.0 (blue) — original version restored
kill %1

echo "Rollback complete. Traffic restored to blue (v1.0)."
```

Time the rollback from decision to verification. For a Service selector patch, end-to-end rollback is complete in under 30 seconds.

---

## Part 6: Review the Audit Trail

Blue-green deployments produce a clear audit trail of every change:

```bash
# List all events related to the service switch
kubectl get events --field-selector reason=Updating --sort-by='.lastTimestamp'

# View the service patch history (in a GitOps workflow, this is in Git)
kubectl describe service webapp

# Show which pods are currently receiving traffic
kubectl get endpoints webapp
kubectl get pods -l version=green -o wide
```

In a production GitOps implementation (Argo CD or Flux), every change to the service selector is a Git commit with author, timestamp, and PR approval chain. The deployment record is inherently auditable.

---

## Part 7: Cleanup

```bash
kubectl delete deployment webapp-blue webapp-green
kubectl delete service webapp
kubectl delete configmap webapp-blue-content webapp-green-content

# If using minikube
minikube stop
```

---

## Verification Exercises

1. **Measure zero-downtime behavior**: Using a loop that polls the service every 100ms during the traffic switch, observe whether any requests fail or return unexpected content during the switch. How does this compare to a rolling deployment with `maxUnavailable: 1`?

2. **Simulate a failed green deployment**: Modify the green readiness probe to point to a path that returns 404 (`/broken`). Deploy green and observe that pods never become Ready. Confirm the Service still routes to blue correctly — the unhealthy deployment has no effect on production traffic because it never received traffic.

3. **Write an automation script**: Create a bash script that performs the full blue-green sequence: smoke test green → switch traffic → verify → cleanup blue after N minutes. Add a `--dry-run` flag.

---

## Reflection Questions

1. In a blue-green deployment, both versions run simultaneously before the switch. What is the resource cost of this approach, and when is it not worth the tradeoff?

2. If the application uses an in-memory session store (not backed by Redis or similar), what happens to active user sessions when traffic switches from blue to green? What architectural change eliminates this problem?

3. Blue-green deployment requires the new version to be backward-compatible with the current database schema during the transition period. Why? What is the maximum time window during which both versions run simultaneously?

4. A compliance requirement states: "All production deployments must be approved by a separate reviewer before taking effect." How does a GitOps blue-green workflow satisfy this requirement compared to a manual deployment process?
