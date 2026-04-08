# Lab — Implementing Progressive Autonomy with Blast Radius Limits

**Chapter:** 13 — AI in Production Operations: Autonomous Remediation Agents and Risk Governance
**Estimated time:** 65–80 minutes
**Difficulty:** Intermediate–Advanced
**Prerequisites:** Familiarity with Python; understanding of agent authorization (Chapter 9); understanding of pipeline controls (Chapter 12)

---

## Objective

Implement a progressive autonomy controller that wraps an AI remediation agent. The controller enforces blast radius limits, autonomy level requirements, dry-run gating, and human escalation triggers. You will observe how the same agent behavior produces different outcomes at different autonomy levels, and verify that actions exceeding policy limits are correctly blocked.

---

## Setup

```bash
cd techstream-learn/book-5-ai-agentic-security/ch13-ai-production-ops/lab
pip install -r requirements.txt
export ANTHROPIC_API_KEY=<your-key>
```

**`requirements.txt`:**
```
anthropic>=0.25.0
pyyaml>=6.0.0
```

---

## Part 1 — Define the Action Policy

Create `action_policy.yaml` with the agent action policy:

```yaml
autonomous_actions:
  pod_restart:
    blast_radius: narrow
    reversibility: reversible_with_data_loss_risk
    max_per_hour: 3
    requires_level: 2

  scale_up:
    blast_radius: service_wide
    reversibility: fully_reversible
    max_scale_factor: 2
    requires_level: 3

  firewall_rule_change:
    blast_radius: cross_service
    reversibility: reversible
    requires_human_approval: true
    requires_level: 4

  secret_rotation:
    blast_radius: platform_wide
    reversibility: partially_reversible
    requires_human_approval: true
    requires_change_ticket: true
    requires_level: 4
```

Implement `action_policy.py`:

```python
import yaml
from pathlib import Path

class ActionPolicy:
    def __init__(self, policy_path: str = "action_policy.yaml"):
        with open(policy_path) as f:
            self._policy = yaml.safe_load(f)["autonomous_actions"]

    def is_allowed(self, action: str, current_level: int) -> tuple[bool, str]:
        if action not in self._policy:
            return False, f"Action '{action}' not in approved policy (implicit deny)"
        spec = self._policy[action]
        required_level = spec.get("requires_level", 99)
        if current_level < required_level:
            return False, (
                f"Action '{action}' requires autonomy level {required_level}, "
                f"current level is {current_level}"
            )
        if spec.get("requires_human_approval") and current_level < 4:
            return False, f"Action '{action}' requires explicit human approval"
        return True, "allowed"

    def get_spec(self, action: str) -> dict:
        return self._policy.get(action, {})
```

---

## Part 2 — Implement the Progressive Autonomy Controller

```python
# autonomy_controller.py
import anthropic
import json
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from collections import defaultdict
from action_policy import ActionPolicy

client = anthropic.Anthropic()

@dataclass
class AutonomyController:
    level: int  # 0=Observe, 1=Suggest, 2=Confirm, 3=Automate, 4=Full
    dry_run: bool = False
    policy: ActionPolicy = field(default_factory=ActionPolicy)
    _action_log: list = field(default_factory=list)
    _action_counts: dict = field(default_factory=lambda: defaultdict(list))
    confirm_timeout_seconds: int = 30

    def _check_rate_limit(self, action: str) -> tuple[bool, str]:
        spec = self.policy.get_spec(action)
        max_per_hour = spec.get("max_per_hour")
        if max_per_hour is None:
            return True, "no rate limit defined"
        cutoff = datetime.now() - timedelta(hours=1)
        recent = [t for t in self._action_counts[action] if t > cutoff]
        if len(recent) >= max_per_hour:
            return False, f"Rate limit exceeded: {action} already executed {len(recent)}x in the last hour (max {max_per_hour})"
        return True, "within rate limit"

    def _log(self, action: str, outcome: str, params: dict):
        self._action_log.append({
            "timestamp": datetime.now().isoformat(),
            "action": action,
            "params": params,
            "outcome": outcome,
            "level": self.level,
            "dry_run": self.dry_run,
        })
        print(f"[AUDIT] {datetime.now().isoformat()} | action={action} | outcome={outcome} | level={self.level} | dry_run={self.dry_run}")

    def execute(self, action: str, params: dict) -> dict:
        # Policy check
        allowed, reason = self.policy.is_allowed(action, self.level)
        if not allowed:
            self._log(action, f"DENIED: {reason}", params)
            return {"status": "denied", "reason": reason}

        # Rate limit check
        rate_ok, rate_msg = self._check_rate_limit(action)
        if not rate_ok:
            self._log(action, f"RATE_LIMITED: {rate_msg}", params)
            return {"status": "rate_limited", "reason": rate_msg}

        # Level-specific handling
        if self.level == 0 or self.dry_run:
            self._log(action, "DRY_RUN: would execute", params)
            return {"status": "dry_run", "would_execute": action, "params": params}

        if self.level == 1:
            print(f"\n[SUGGEST] Agent recommends: {action} with params {params}")
            approval = input("Approve this action? [yes/no]: ").strip().lower()
            if approval != "yes":
                self._log(action, "VETOED_BY_HUMAN", params)
                return {"status": "vetoed", "action": action}

        if self.level == 2:
            spec = self.policy.get_spec(action)
            if spec.get("reversibility") not in ("fully_reversible", "reversible"):
                print(f"\n[CONFIRM] Agent will execute: {action} in {self.confirm_timeout_seconds}s. Press ENTER to veto.")
                import select, sys
                ready, _, _ = select.select([sys.stdin], [], [], self.confirm_timeout_seconds)
                if ready:
                    self._log(action, "VETOED_IN_WINDOW", params)
                    return {"status": "vetoed", "action": action}

        # Execute (simulated)
        self._action_counts[action].append(datetime.now())
        self._log(action, "EXECUTED", params)
        return {"status": "executed", "action": action, "params": params}
```

---

## Part 3 — Wire to an AI Remediation Agent

```python
# remediation_agent.py
import anthropic, json
from autonomy_controller import AutonomyController

client = anthropic.Anthropic()

TOOLS = [
    {
        "name": "pod_restart",
        "description": "Restart a Kubernetes pod that is in a crash loop or unresponsive state.",
        "input_schema": {
            "type": "object",
            "properties": {
                "namespace": {"type": "string"},
                "pod_name": {"type": "string"},
                "reason": {"type": "string"}
            },
            "required": ["namespace", "pod_name", "reason"]
        }
    },
    {
        "name": "scale_up",
        "description": "Scale a service deployment to handle increased load.",
        "input_schema": {
            "type": "object",
            "properties": {
                "service": {"type": "string"},
                "current_replicas": {"type": "integer"},
                "target_replicas": {"type": "integer"},
                "reason": {"type": "string"}
            },
            "required": ["service", "current_replicas", "target_replicas", "reason"]
        }
    },
    {
        "name": "secret_rotation",
        "description": "Rotate a service secret or API key.",
        "input_schema": {
            "type": "object",
            "properties": {
                "secret_name": {"type": "string"},
                "service": {"type": "string"},
                "reason": {"type": "string"}
            },
            "required": ["secret_name", "service", "reason"]
        }
    }
]

def run_remediation_agent(incident: dict, controller: AutonomyController):
    print(f"\n[AGENT] Analyzing incident: {incident['description']}")

    messages = [{"role": "user", "content": f"Incident report: {json.dumps(incident)}. Diagnose the issue and take the appropriate remediation action."}]

    response = client.messages.create(
        model="claude-haiku-4-5-20251001",
        max_tokens=1024,
        tools=TOOLS,
        messages=messages
    )

    for block in response.content:
        if block.type == "tool_use":
            print(f"\n[AGENT] Requesting action: {block.name}")
            result = controller.execute(block.name, block.input)
            print(f"[CONTROLLER] Result: {result}")
            return result

    print(f"[AGENT] No action taken. Response: {response.content[0].text if response.content else 'empty'}")
    return {"status": "no_action"}
```

---

## Exercises

**Exercise 1 — Observe mode (Level 0):**

```python
from autonomy_controller import AutonomyController
from remediation_agent import run_remediation_agent

controller = AutonomyController(level=0, dry_run=True)
incident = {
    "description": "Pod api-gateway-7d4b9c is crash-looping in namespace production. OOMKilled 3 times in the last 10 minutes.",
    "severity": "high"
}
run_remediation_agent(incident, controller)
```

Expected: Agent recommends `pod_restart`. Controller reports `dry_run: would execute`. No execution occurs.

**Exercise 2 — Suggest mode (Level 1):**

```python
controller = AutonomyController(level=1)
run_remediation_agent(incident, controller)
```

Respond `yes` at the approval prompt. Verify execution is logged. Then run again and respond `no`. Verify veto is logged.

**Exercise 3 — Blocked by policy (secret rotation at Level 2):**

```python
controller = AutonomyController(level=2)
secret_incident = {
    "description": "Credential scanning detected that the payment-service API key may have been exposed in a public repository. Immediate rotation required.",
    "severity": "critical"
}
run_remediation_agent(secret_incident, controller)
```

Expected: `secret_rotation` is denied because it requires Level 4. Verify the denial reason in the audit log.

**Exercise 4 — Rate limit enforcement:**

```python
controller = AutonomyController(level=3)
# Execute pod_restart 3 times rapidly (up to the hourly limit)
for i in range(4):
    result = controller.execute("pod_restart", {
        "namespace": "production",
        "pod_name": f"api-gateway-{i}",
        "reason": "crash loop"
    })
    print(f"Attempt {i+1}: {result['status']}")
```

Expected: First 3 executions succeed. Fourth is rate-limited.

**Exercise 5 — Policy implicit deny:**

```python
controller = AutonomyController(level=4)
result = controller.execute("database_failover", {"db": "payments-primary", "reason": "latency spike"})
print(result)
```

Expected: `database_failover` is not in the policy and is implicitly denied.

---

## Reflection Questions

1. The progressive autonomy model advances agents level-by-level. What evidence would you collect during the Level 1 (Suggest) phase to justify advancement to Level 2 (Confirm)? Define a concrete measurement methodology.

2. The dry-run and shadow mode are described as mandatory before advancing from Level 0. Design a shadow mode test harness that compares agent actions to human operator decisions for a given set of historical incidents. What accuracy threshold would you require before advancing?

3. The governance board model requires monthly review of action audit logs. For a high-volume production environment with 10,000 agent actions per month, how would you structure the audit log review to make it tractable? What statistical sampling or anomaly detection approach would you use?

---

## Framework Reference

`ai-devsecops-framework/docs/production-operations.md`

## Learning Checkpoint

After completing this lab you should be able to:
- Define and enforce blast radius limits and rate limits on autonomous agent actions using a policy file
- Implement a progressive autonomy controller that enforces per-level approval, confirmation window, and human escalation semantics
- Wire a tool-calling AI agent to an autonomy controller that mediates all tool executions
- Test policy enforcement through explicit denial, rate limiting, and implicit deny scenarios
- Identify the evidence required to justify advancing agent autonomy from one level to the next
