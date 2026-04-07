"""
slack-notifier-lambda.py — Lambda function for routing Security Hub findings to Slack

Triggered by EventBridge rule on Security Hub finding import events.
Translates AWS Security Finding Format (ASFF) to a Slack message.

Environment variables:
  SLACK_WEBHOOK_URL — Incoming webhook URL for your Slack channel
  MIN_SEVERITY — Minimum severity to alert on (CRITICAL, HIGH, MEDIUM) — default: HIGH
"""

import json
import os
import urllib.request
from datetime import datetime


def lambda_handler(event, context):
    webhook_url = os.environ.get("SLACK_WEBHOOK_URL")
    min_severity = os.environ.get("MIN_SEVERITY", "HIGH")

    severity_order = {"CRITICAL": 0, "HIGH": 1, "MEDIUM": 2, "LOW": 3, "INFORMATIONAL": 4}

    findings = event.get("detail", {}).get("findings", [])

    for finding in findings:
        severity_label = finding.get("Severity", {}).get("Label", "UNKNOWN")

        # Filter by minimum severity
        if severity_order.get(severity_label, 99) > severity_order.get(min_severity, 1):
            continue

        # Extract key fields from ASFF
        title         = finding.get("Title", "Unknown finding")
        description   = finding.get("Description", "")
        account_id    = finding.get("AwsAccountId", "")
        region        = finding.get("Region", "")
        control_id    = finding.get("ProductFields", {}).get("ControlId", "")
        resource_id   = finding.get("Resources", [{}])[0].get("Id", "")
        remediation   = finding.get("Remediation", {}).get("Recommendation", {}).get("Text", "See Security Hub")
        finding_url   = finding.get("Remediation", {}).get("Recommendation", {}).get("Url", "")

        # Map severity to Slack color
        color_map = {"CRITICAL": "#FF0000", "HIGH": "#FF6600", "MEDIUM": "#FFCC00", "LOW": "#36A64F"}
        color = color_map.get(severity_label, "#808080")

        # Build Slack message (Block Kit)
        message = {
            "text": f":rotating_light: *Security Hub — {severity_label} Finding*",
            "attachments": [
                {
                    "color": color,
                    "fields": [
                        {"title": "Finding",     "value": title,       "short": False},
                        {"title": "Control",     "value": control_id,  "short": True},
                        {"title": "Severity",    "value": severity_label, "short": True},
                        {"title": "Account",     "value": account_id,  "short": True},
                        {"title": "Region",      "value": region,      "short": True},
                        {"title": "Resource",    "value": resource_id, "short": False},
                        {"title": "Remediation", "value": f"<{finding_url}|{remediation}>" if finding_url else remediation, "short": False},
                    ],
                    "footer": "AWS Security Hub",
                    "ts": int(datetime.now().timestamp()),
                }
            ],
        }

        if webhook_url:
            req = urllib.request.Request(
                webhook_url,
                data=json.dumps(message).encode("utf-8"),
                headers={"Content-Type": "application/json"},
                method="POST",
            )
            with urllib.request.urlopen(req) as resp:
                print(f"Slack notification sent: {resp.status} — {title}")
        else:
            print(f"SLACK_WEBHOOK_URL not set — would have sent: {title}")

    return {"statusCode": 200}
