"""
custom-config-rule.py — AWS Config custom rule: S3 buckets must have a CostCenter tag

This Lambda function is triggered by AWS Config when an S3 bucket's configuration changes.
It evaluates whether the bucket has the required 'CostCenter' tag and reports the result
back to Config, which surfaces it in Security Hub.

Required IAM permissions for the Lambda execution role:
  - config:PutEvaluations
  - s3:GetBucketTagging
"""

import json
import boto3


def lambda_handler(event, context):
    config_client = boto3.client("config")

    invoking_event = json.loads(event["invokingEvent"])
    config_item    = invoking_event.get("configurationItem", {})

    # Only evaluate S3 bucket resources
    if config_item.get("resourceType") != "AWS::S3::Bucket":
        return

    bucket_name    = config_item.get("resourceName")
    capture_time   = config_item.get("configurationItemCaptureTime")
    resource_id    = config_item.get("resourceId")
    account_id     = config_item.get("awsAccountId")

    # Evaluate: does the bucket have a CostCenter tag?
    tags = config_item.get("tags", {})
    compliance_type = "NON_COMPLIANT" if "CostCenter" not in tags else "COMPLIANT"

    annotation = (
        f"Bucket '{bucket_name}' is missing the required 'CostCenter' tag. "
        f"All S3 buckets must have a CostCenter tag for cost allocation and compliance."
        if compliance_type == "NON_COMPLIANT"
        else f"Bucket '{bucket_name}' has the required CostCenter tag: {tags.get('CostCenter')}"
    )

    evaluation = {
        "ComplianceResourceType": "AWS::S3::Bucket",
        "ComplianceResourceId":   resource_id,
        "ComplianceType":         compliance_type,
        "Annotation":             annotation,
        "OrderingTimestamp":      capture_time,
    }

    config_client.put_evaluations(
        Evaluations=[evaluation],
        ResultToken=event["resultToken"],
    )

    print(f"Evaluated {bucket_name}: {compliance_type} — {annotation}")
