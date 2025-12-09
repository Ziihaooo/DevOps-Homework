import json
import os
import boto3
import uuid
import logging

# -----------------------
# Logging setup
# -----------------------
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def log_json(action, client, fqdn, target, status, error=None):
    """Structured JSON logging for CloudWatch Logs"""
    record = {
        "request_id": str(uuid.uuid4()),
        "action": action,
        "client": client,
        "subdomain": fqdn,
        "target_domain": target,
        "status": status,
        "error_message": error,
    }
    logger.info(json.dumps(record))


# -----------------------
# AWS Clients
# -----------------------
route53 = boto3.client("route53")
cloudwatch = boto3.client("cloudwatch")


def lambda_handler(event, context):

    print("Raw event:", json.dumps(event))

    hosted_zone_id = os.environ["HOSTED_ZONE_ID"]
    base_domain = os.environ["BASE_DOMAIN"]

    for record in event.get("Records", []):

        body = record.get("body")
        if not body:
            print("Skipping empty message")
            continue

        try:
            msg = json.loads(body)
        except json.JSONDecodeError:
            print("Invalid JSON:", body)
            continue

        print("Parsed message:", msg)

        # -----------------------
        # Validate required fields
        # -----------------------
        required = [
            "action",
            "client",
            "source_env",
            "target_env",
            "record_type",
            "target_value"
        ]

        missing = [f for f in required if f not in msg]
        if missing:
            raise ValueError(f"Missing fields: {missing}")

        if msg["source_env"] != "staging":
            raise ValueError("source_env must be 'staging'")

        if msg["target_env"] != "production":
            raise ValueError("target_env must be 'production'")

        action = msg["action"]
        client = msg["client"]
        record_type = msg["record_type"]
        target_value = msg["target_value"]
        ttl = msg.get("ttl", 300)

        if action not in ["add", "update", "delete"]:
            raise ValueError(f"Invalid action: {action}")

        # -----------------------
        # Compute FQDN
        # -----------------------
        fqdn = f"{client}.{base_domain}".rstrip(".")
        print(f"FQDN resolved as: {fqdn}")

        # -----------------------
        # Determine R53 change type
        # -----------------------
        route53_action = {
            "add": "CREATE",
            "update": "UPSERT",
            "delete": "DELETE"
        }[action]

        resource_records = [] if action == "delete" else [{"Value": target_value}]

        dns_change = {
            "Comment": f"Automated DNS {action} request",
            "Changes": [
                {
                    "Action": route53_action,
                    "ResourceRecordSet": {
                        "Name": fqdn,
                        "Type": record_type,
                        "TTL": ttl,
                        "ResourceRecords": resource_records
                    }
                }
            ]
        }

        print("Submitting Route53 change:", json.dumps(dns_change))

        # -----------------------
        # EXECUTE ROUTE53 CHANGE
        # -----------------------
        try:
            response = route53.change_resource_record_sets(
                HostedZoneId=hosted_zone_id,
                ChangeBatch=dns_change
            )
            print("Route53 Response:", response)

            # Structured log (success)
            log_json(action, client, fqdn, target_value, "success")

            # SAFE metric write
            try:
                cloudwatch.put_metric_data(
                    Namespace="ClientDomainSystem",
                    MetricData=[
                        {
                            "MetricName": "SuccessCount",
                            "Dimensions": [
                                {"Name": "Client", "Value": client},
                                {"Name": "Action", "Value": action},
                            ],
                            "Value": 1,
                            "Unit": "Count",
                        },
                        {
                            "MetricName": "SuccessTotal",
                            "Value": 1,
                            "Unit": "Count"
                        }
                    ],
                )
            except Exception as metric_err:
                print("Metric write failed:", str(metric_err))

        except Exception as ex:

            err = str(ex)
            print("Route53 Error:", err)

            # Structured log (failure)
            log_json(action, client, fqdn, target_value, "failure", err)

            # Metric failure (safe)
            try:
                cloudwatch.put_metric_data(
                    Namespace="ClientDomainSystem",
                    MetricData=[
                        {
                            "MetricName": "FailureCount",
                            "Dimensions": [
                                {"Name": "Client", "Value": client},
                                {"Name": "Action", "Value": action},
                            ],
                            "Value": 1,
                            "Unit": "Count",
                        },
                        {
                            "MetricName": "FailureTotal",
                            "Value": 1,
                            "Unit": "Count"
                        }

                    ],
                )
            except Exception as metric_err:
                print("Metric write failed:", str(metric_err))

            raise ex

    return {"status": "ok", "message": "All SQS messages processed"}
