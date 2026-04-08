# Lab 10 — Cloud and Container Forensic Investigation

**Estimated time:** 75–90 minutes
**Difficulty:** Intermediate–Advanced
**Prerequisites:** Familiarity with Kubernetes concepts (pods, service accounts, RBAC); familiarity with AWS IAM and CloudTrail; ability to read JSON log formats

---

## Objective

By the end of this lab you will be able to:
- Analyze a Kubernetes API server audit log to identify reconnaissance and privilege escalation attempts
- Determine whether a container registry image tag was mutated after a known-good deployment
- Trace the actions of a compromised OIDC federation token through CloudTrail logs
- Identify the forensic limitations of each cloud/container evidence source

---

## Scenario 1 — Kubernetes API Server Audit Log Analysis (30 minutes)

The following is an extract from a Kubernetes API server audit log covering a 3-hour window. You have been asked to investigate a suspected service account compromise.

```json
[
  {
    "kind": "Event",
    "apiVersion": "audit.k8s.io/v1",
    "level": "RequestResponse",
    "auditID": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "stage": "ResponseComplete",
    "requestURI": "/api/v1/namespaces/production/secrets",
    "verb": "list",
    "user": {
      "username": "system:serviceaccount:ci-cd:deploy-agent",
      "groups": ["system:serviceaccounts", "system:serviceaccounts:ci-cd", "system:authenticated"]
    },
    "sourceIPs": ["10.0.4.23"],
    "objectRef": { "resource": "secrets", "namespace": "production" },
    "responseStatus": { "code": 200 },
    "requestReceivedTimestamp": "2024-07-08T11:03:14.293Z"
  },
  {
    "auditID": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
    "verb": "get",
    "user": { "username": "system:serviceaccount:ci-cd:deploy-agent" },
    "requestURI": "/api/v1/namespaces/production/secrets/prod-db-password",
    "responseStatus": { "code": 200 },
    "requestReceivedTimestamp": "2024-07-08T11:03:16.102Z"
  },
  {
    "auditID": "c3d4e5f6-a7b8-9012-cdef-123456789012",
    "verb": "get",
    "user": { "username": "system:serviceaccount:ci-cd:deploy-agent" },
    "requestURI": "/api/v1/namespaces/production/secrets/prod-api-key",
    "responseStatus": { "code": 200 },
    "requestReceivedTimestamp": "2024-07-08T11:03:17.441Z"
  },
  {
    "auditID": "d4e5f6a7-b8c9-0123-defa-234567890123",
    "verb": "list",
    "user": { "username": "system:serviceaccount:ci-cd:deploy-agent" },
    "requestURI": "/apis/rbac.authorization.k8s.io/v1/clusterrolebindings",
    "responseStatus": { "code": 200 },
    "requestReceivedTimestamp": "2024-07-08T11:04:02.887Z"
  },
  {
    "auditID": "e5f6a7b8-c9d0-1234-efab-345678901234",
    "verb": "create",
    "user": { "username": "system:serviceaccount:ci-cd:deploy-agent" },
    "requestURI": "/apis/rbac.authorization.k8s.io/v1/clusterrolebindings",
    "requestObject": {
      "metadata": { "name": "deploy-agent-cluster-admin" },
      "roleRef": { "kind": "ClusterRole", "name": "cluster-admin" },
      "subjects": [{ "kind": "ServiceAccount", "name": "deploy-agent", "namespace": "ci-cd" }]
    },
    "responseStatus": { "code": 403 },
    "requestReceivedTimestamp": "2024-07-08T11:04:08.221Z"
  },
  {
    "auditID": "f6a7b8c9-d0e1-2345-fabc-456789012345",
    "verb": "create",
    "user": { "username": "system:serviceaccount:ci-cd:deploy-agent" },
    "requestURI": "/api/v1/namespaces/kube-system/pods",
    "requestObject": {
      "metadata": { "name": "debug-pod" },
      "spec": {
        "hostPID": true,
        "hostNetwork": true,
        "containers": [{
          "name": "debug",
          "image": "alpine:3.18",
          "securityContext": { "privileged": true },
          "command": ["/bin/sh", "-c", "nsenter -t 1 -m -u -i -n -- bash"]
        }]
      }
    },
    "responseStatus": { "code": 403 },
    "requestReceivedTimestamp": "2024-07-08T11:04:31.774Z"
  }
]
```

**Questions:**

1. The `deploy-agent` service account is supposed to be used only by the CI/CD deployment pipeline, which runs during business hours and only deploys to the `staging` namespace. Identify all indicators of anomalous behavior in the audit log above, with timestamps.

2. Classify the sequence of API calls as a kill chain: what was the attacker attempting to do, in what order, and which attempts succeeded versus failed?

3. The two privilege escalation attempts (ClusterRoleBinding creation and privileged pod creation) both returned 403. What does this tell you about the RBAC configuration? What should be immediately revoked or rotated as a result of the succeeded calls?

4. What evidence is missing from the Kubernetes audit log that would give you a complete picture of the incident? Where would you look for that evidence?

---

## Scenario 2 — Container Registry Tag Mutation Investigation (20 minutes)

Your organization deploys container images using mutable tags (e.g., `registry.internal.io/payments:v2.4.1`). A security review has flagged that the `payments:v2.4.1` image currently in production has a different digest than the image that was used to generate the deployment SLSA attestation.

The following registry audit log records are available:

```json
[
  {
    "action": "push",
    "tag": "v2.4.1",
    "digest": "sha256:aabbccdd11223344556677889900aabbccdd11223344556677889900aabbccdd11",
    "actor": "ci-pipeline@serviceaccount.internal",
    "timestamp": "2024-07-01T14:22:09Z",
    "sourceIP": "10.0.1.50"
  },
  {
    "action": "pull",
    "tag": "v2.4.1",
    "digest": "sha256:aabbccdd11223344556677889900aabbccdd11223344556677889900aabbccdd11",
    "actor": "deploy-system@serviceaccount.internal",
    "timestamp": "2024-07-01T14:35:00Z",
    "sourceIP": "10.0.2.15"
  },
  {
    "action": "push",
    "tag": "v2.4.1",
    "digest": "sha256:99887766554433221100ffeeddccbbaa99887766554433221100ffeeddccbbaa99",
    "actor": "unknown-identity@external",
    "timestamp": "2024-07-04T03:17:44Z",
    "sourceIP": "203.0.113.88"
  }
]
```

**Questions:**

1. At what time was the tag mutated, by whom, and from what source IP? What does the source IP suggest?

2. Between the initial push and the mutation, the image was pulled once. Is that pull record consistent with a normal deployment workflow?

3. The deployment system pulls images by tag, not digest. Production is currently running the mutated image. What immediate actions are required?

4. How would you determine whether the mutated image has been running in production long enough to have taken any harmful actions? What evidence sources would you use?

5. What architectural change would have prevented this attack entirely? What is the operational cost of that change?

---

## Scenario 3 — OIDC Token Compromise via CloudTrail (25 minutes)

A GitHub Actions OIDC token was issued to a build job at 14:00 UTC on 2024-07-10. The token was valid for 1 hour. Threat intelligence indicates that the build environment may have been compromised by a malicious npm package that captures and exfiltrates OIDC tokens.

The following CloudTrail events were recorded for the IAM role assumed by this token:

```json
[
  { "eventTime": "2024-07-10T14:00:43Z", "eventName": "AssumeRoleWithWebIdentity",
    "requestParameters": { "roleArn": "arn:aws:iam::999888777666:role/github-build-role" },
    "sourceIPAddress": "192.0.2.44" },

  { "eventTime": "2024-07-10T14:01:02Z", "eventName": "GetSecretValue",
    "requestParameters": { "secretId": "build/npm-token" },
    "sourceIPAddress": "192.0.2.44" },

  { "eventTime": "2024-07-10T14:07:33Z", "eventName": "PutObject",
    "requestParameters": { "bucketName": "meridian-build-artifacts", "key": "builds/2024-07-10/api-build-14-00.tar.gz" },
    "sourceIPAddress": "192.0.2.44" },

  { "eventTime": "2024-07-10T14:47:19Z", "eventName": "AssumeRole",
    "requestParameters": { "roleArn": "arn:aws:iam::999888777666:role/github-build-role",
                          "roleSessionName": "external-session-7x9k2" },
    "sourceIPAddress": "198.51.100.200" },

  { "eventTime": "2024-07-10T14:47:44Z", "eventName": "ListBuckets",
    "sourceIPAddress": "198.51.100.200" },

  { "eventTime": "2024-07-10T14:48:01Z", "eventName": "GetObject",
    "requestParameters": { "bucketName": "meridian-customer-data", "key": "exports/2024-Q2-customer-list.csv" },
    "sourceIPAddress": "198.51.100.200" },

  { "eventTime": "2024-07-10T14:55:33Z", "eventName": "GetSecretValue",
    "requestParameters": { "secretId": "prod/stripe-api-key" },
    "sourceIPAddress": "198.51.100.200" }
]
```

**Questions:**

1. Separate the legitimate pipeline activity from the attacker's activity. At what time did the attacker begin using the stolen token, and from which IP address?

2. The attacker called `AssumeRole` to create a new session. What does this tell you about the IAM role's trust policy? What additional capability does this give the attacker?

3. List all specific resources accessed by the attacker with evidence citations. For each resource, describe the potential impact.

4. The OIDC token expired at 15:00:43 UTC. The attacker's assumed role session may have a longer lifetime. What immediate revocation action is required?

5. Write a 3-sentence summary of the blast radius suitable for inclusion in a security incident report.

---

## Summary

Cloud and container forensic investigations depend entirely on evidence that must be configured before the incident. Kubernetes API server audit logs, container registry mutation records, and CloudTrail events provide a complete and correlated picture of attacker activity — but only if they are enabled, retained, and accessible.

The three scenarios in this lab illustrate the three most common cloud/container investigation patterns: service account abuse (Scenario 1), supply chain via image mutation (Scenario 2), and credential theft via pipeline compromise (Scenario 3). Each requires a different primary evidence source and a different remediation path.

---

## Further Reading

- Chapter 5 (in the book): Immutable Audit Trails — ensuring CloudTrail and Kubernetes audit logs are tamper-resistant
- Chapter 7: Cloud and Container Forensic Artifacts — full catalog of evidence sources for each environment type
- [Kubernetes API server audit logging](https://kubernetes.io/docs/tasks/debug/debug-cluster/audit/) — configuration reference
- [AWS CloudTrail best practices](https://docs.aws.amazon.com/awscloudtrail/latest/userguide/best-practices-security.html)
