# Lab 4 — Feature Flag Rollout and Rollback Using Environment-Based Configuration

**Estimated time:** 40–55 minutes
**Difficulty:** Beginner–Intermediate
**Prerequisites:**
- Python 3.9+ installed (or Docker)
- Basic Python familiarity
- No external services required — this lab uses file-based flag configuration

---

## Overview

You will implement a minimal feature flag system using environment variables and JSON configuration files. This approach represents how feature flags work before adopting a dedicated flag management platform — it is not production-grade but demonstrates the core evaluation logic that all flag systems implement.

The scenario: your team has built a new checkout flow and wants to roll it out to 10% of users, expand to 50%, then 100%, with a kill switch available at each stage.

---

## Part 1: Environment-Based Kill Switch (10 minutes)

The simplest feature flag is an environment variable that controls a code path. No infrastructure required.

Save this as `flag_demo.py`:

```python
import os
import hashlib

# --- Kill switch: environment variable controls entire feature ---
def new_checkout_enabled() -> bool:
    """Global kill switch. Set ENABLE_NEW_CHECKOUT=false to disable instantly."""
    return os.getenv("ENABLE_NEW_CHECKOUT", "false").lower() == "true"


# --- Percentage rollout: deterministic hash-based user assignment ---
def new_checkout_enabled_for_user(user_id: str, rollout_percentage: int = 10) -> bool:
    """
    Returns True if the new checkout is enabled for this user.
    Assignment is deterministic: same user_id always gets the same result.
    """
    if not new_checkout_enabled():
        return False  # Kill switch overrides percentage rollout

    # Hash the user_id to a bucket 0-99
    hash_val = int(hashlib.md5(f"new_checkout:{user_id}".encode()).hexdigest(), 16)
    bucket = hash_val % 100
    return bucket < rollout_percentage


# --- Simulate the checkout code path ---
def checkout(user_id: str, cart: dict, rollout_pct: int = 10) -> str:
    if new_checkout_enabled_for_user(user_id, rollout_pct):
        return f"[NEW] Checkout complete for {user_id}: {cart}"
    else:
        return f"[LEGACY] Checkout complete for {user_id}: {cart}"


# --- Test with sample users ---
if __name__ == "__main__":
    users = [f"user_{i:04d}" for i in range(20)]
    rollout_pct = int(os.getenv("ROLLOUT_PCT", "10"))

    print(f"Kill switch: ENABLE_NEW_CHECKOUT={os.getenv('ENABLE_NEW_CHECKOUT', 'false')}")
    print(f"Rollout percentage: {rollout_pct}%")
    print()

    for user_id in users:
        result = checkout(user_id, {"item": "widget", "qty": 1}, rollout_pct)
        print(result)
```

**Run at 0% (kill switch off):**
```bash
python flag_demo.py
```

**Run at 10% rollout:**
```bash
ENABLE_NEW_CHECKOUT=true ROLLOUT_PCT=10 python flag_demo.py
```

**Run at 50% rollout:**
```bash
ENABLE_NEW_CHECKOUT=true ROLLOUT_PCT=50 python flag_demo.py
```

**Kill switch in action — disable immediately without redeployment:**
```bash
ENABLE_NEW_CHECKOUT=false ROLLOUT_PCT=100 python flag_demo.py
```

Note: even at 100% rollout, the kill switch (`ENABLE_NEW_CHECKOUT=false`) disables the feature for all users. This simulates what a feature flag platform does when you flip a flag off in production.

---

## Part 2: Verify Deterministic User Assignment (10 minutes)

Run the 10% rollout twice. Observe that the same users get the new checkout each time. This is the determinism property — it is critical for user experience (no flickering) and for measuring feature impact.

```bash
echo "=== Run 1 ==="
ENABLE_NEW_CHECKOUT=true ROLLOUT_PCT=10 python flag_demo.py | grep '\[NEW\]'

echo "=== Run 2 ==="
ENABLE_NEW_CHECKOUT=true ROLLOUT_PCT=10 python flag_demo.py | grep '\[NEW\]'
```

Both runs should show the same users receiving the new checkout.

Now test that expanding the rollout includes new users without removing existing ones:

```bash
echo "=== 10% rollout — users in new checkout ==="
ENABLE_NEW_CHECKOUT=true ROLLOUT_PCT=10 python flag_demo.py | grep '\[NEW\]' | awk '{print $1}'

echo "=== 30% rollout — all 10% users still included + new ones ==="
ENABLE_NEW_CHECKOUT=true ROLLOUT_PCT=30 python flag_demo.py | grep '\[NEW\]' | awk '{print $1}'
```

Users from the 10% cohort should all appear in the 30% cohort.

---

## Part 3: JSON-Based Flag Configuration (15 minutes)

Production feature flag systems use a centralized configuration store, not individual environment variables. This part simulates that with a JSON file.

Create `flags.json`:

```json
{
  "new_checkout_flow": {
    "enabled": true,
    "rollout_percentage": 25,
    "owner": "payments-team",
    "expires": "2026-06-01",
    "description": "New Stripe-integrated checkout flow"
  },
  "dark_mode": {
    "enabled": false,
    "rollout_percentage": 0,
    "owner": "frontend-team",
    "expires": "2026-05-01",
    "description": "Dark mode UI — internal beta only"
  }
}
```

Save this as `flag_config.py`:

```python
import json
import hashlib
from datetime import date

def load_flags(path: str = "flags.json") -> dict:
    with open(path) as f:
        return json.load(f)

def is_enabled(flag_name: str, user_id: str, flags: dict) -> bool:
    flag = flags.get(flag_name)
    if not flag or not flag.get("enabled"):
        return False

    # Check expiry
    expires = flag.get("expires")
    if expires and date.today() > date.fromisoformat(expires):
        print(f"WARNING: Flag '{flag_name}' has expired ({expires}) — treating as disabled")
        return False

    pct = flag.get("rollout_percentage", 0)
    bucket = int(hashlib.md5(f"{flag_name}:{user_id}".encode()).hexdigest(), 16) % 100
    return bucket < pct

if __name__ == "__main__":
    flags = load_flags()
    test_users = [f"user_{i:04d}" for i in range(10)]

    for flag_name in flags:
        enabled_for = [u for u in test_users if is_enabled(flag_name, u, flags)]
        print(f"{flag_name}: enabled for {len(enabled_for)}/10 test users → {enabled_for}")
```

Run:
```bash
python flag_config.py
```

**Rollback simulation:** Edit `flags.json` and set `new_checkout_flow.enabled` to `false`. Re-run — the flag is now disabled for all users without changing any application code.

---

## Part 4: Flag Cleanup Audit (10 minutes)

Write a simple flag audit script that flags (pun intended) candidates for cleanup:

```python
import json
from datetime import date

def audit_flags(path: str = "flags.json"):
    with open(path) as f:
        flags = json.load(f)

    today = date.today()
    print(f"Flag Audit Report — {today}\n")

    for name, flag in flags.items():
        issues = []

        if not flag.get("owner"):
            issues.append("NO OWNER")

        expires = flag.get("expires")
        if not expires:
            issues.append("NO EXPIRY DATE")
        elif date.fromisoformat(expires) < today:
            issues.append(f"EXPIRED ({expires})")

        pct = flag.get("rollout_percentage", 0)
        if flag.get("enabled") and pct == 100:
            issues.append("AT 100% — candidate for cleanup")

        if flag.get("enabled") is False and pct == 0:
            issues.append("DISABLED + 0% — candidate for removal")

        status = "CLEAN" if not issues else f"ACTION NEEDED: {', '.join(issues)}"
        print(f"  {name}: {status}")

if __name__ == "__main__":
    audit_flags()
```

Run:
```bash
python audit_flags.py
```

Add a flag at 100% with no expiry to `flags.json` and re-run to see the cleanup warning.

---

## Reflection Questions

1. The deterministic hash uses `f"{flag_name}:{user_id}"` as the hash input rather than just `user_id`. Why is the flag name included? What problem would occur if you only hashed the user ID?

2. A product manager asks to use a feature flag to store a configuration value: "just put the API endpoint URL in the flag value." What is the problem with this approach, and what is the correct solution?

3. The kill switch pattern (`ENABLE_NEW_CHECKOUT=false`) works by checking the environment variable at request time. If your application caches flag state at startup (common for performance), how does this affect kill switch response time? What is the trade-off?

4. Your team has 47 feature flags in production. 12 have been at 100% rollout for over 3 months. What is the risk of leaving them in place? Write a one-paragraph argument for the next sprint planning meeting to prioritize flag cleanup.
