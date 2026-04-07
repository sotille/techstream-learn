"""
custom_checks/check_required_tags.py

Custom Checkov policy: enforce Techstream-required resource tags.
All supported resource types must have 'Environment' and 'DataClass' tags.

Usage:
  checkov -d . --external-checks-dir custom_checks --check CKV_CUSTOM_1

This check demonstrates how organizations extend Checkov with internal
compliance controls that are not covered by built-in rules.
"""

from checkov.common.models.enums import CheckResult, CheckCategories
from checkov.terraform.checks.resource.base_resource_check import BaseResourceCheck


class CheckRequiredTags(BaseResourceCheck):
    """
    Enforce that all supported resource types have the required
    Techstream tagging standard tags: Environment and DataClass.

    These tags are required for:
    - Cost allocation by environment tier
    - Data classification for compliance scoping
    - Automated policy enforcement based on data sensitivity
    """

    REQUIRED_TAGS = {"Environment", "DataClass"}

    VALID_ENVIRONMENTS = {"production", "staging", "development", "sandbox"}
    VALID_DATA_CLASSES = {"sensitive", "internal", "public", "restricted"}

    def __init__(self):
        name = "Ensure all resources have required Techstream tags"
        id = "CKV_CUSTOM_1"
        supported_resources = [
            "aws_s3_bucket",
            "aws_db_instance",
            "aws_instance",
            "aws_eks_cluster",
            "aws_lambda_function",
            "aws_sqs_queue",
            "aws_sns_topic",
        ]
        categories = [CheckCategories.GENERAL_SECURITY]
        super().__init__(
            name=name,
            id=id,
            categories=categories,
            supported_resources=supported_resources,
        )

    def scan_resource_conf(self, conf):
        """
        Check that the resource has all required tags with valid values.
        Returns PASSED if all required tags are present and valid.
        Returns FAILED if any required tag is missing or has an invalid value.
        """
        tags = conf.get("tags")

        if not tags:
            return CheckResult.FAILED

        # Terraform passes tags as a list containing a dict
        if isinstance(tags, list):
            tags = tags[0] if tags else {}

        if not isinstance(tags, dict):
            return CheckResult.FAILED

        # Check all required tags are present
        missing_tags = self.REQUIRED_TAGS - set(tags.keys())
        if missing_tags:
            return CheckResult.FAILED

        # Optionally validate tag values (comment out if values vary)
        env_value = tags.get("Environment", "").lower()
        if env_value not in self.VALID_ENVIRONMENTS:
            return CheckResult.FAILED

        data_class_value = tags.get("DataClass", "").lower()
        if data_class_value not in self.VALID_DATA_CLASSES:
            return CheckResult.FAILED

        return CheckResult.PASSED


scanner = CheckRequiredTags()
