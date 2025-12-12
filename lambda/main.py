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

def safe_log_error(msg, raw=None):
    """Ensure ANY error will be logged without breaking system"""
    try:
        log_json(
            action="unknown",
            client="unknown",
            fqdn="unknown",
            target=str(raw),
            status="failure",
            error=msg
        )
    except Exception as e:
        print("Failed to write structured error log:", str(e))


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
            safe_log_error("Empty message received")
            continue

        # -----------------------
        # JSON PARSE ERROR LOGGING
        # -----------------------
        try:
            msg = json.loads(body)
        except json.JSONDecodeError as e:
            print("Invalid JSON:", body)
            safe_log_error(f"JSON decode error: {str(e)}", body)
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
            safe_log_error(f"Missing fields: {missing}", msg)
            raise ValueError(f"Missing fields: {missing}")

        if msg["source_env"] != "staging":
            safe_log_error("Invalid source_env (must be 'staging')", msg)
            raise ValueError("source_env must be 'staging'")

        if msg["target_env"] != "production":
            safe_log_error("Invalid target_env (must be 'production')", msg)
            raise ValueError("target_env must be 'production'")

        action = msg["action"]
        client = msg["client"]
        record_type = msg["record_type"]
        target_value = msg["target_value"]
        ttl = msg.get("ttl", 300)

        if action not in ["add", "update", "delete"]:
            safe_log_error(f"Invalid action: {action}", msg)
            raise ValueError(f"Invalid action: {action}")

        # -----------------------
        # Compute FQDN
        # -----------------------
        fqdn = f"{client}.production.{base_domain}".rstrip(".")

        print(f"FQDN resolved as: {fqdn}")

        # -----------------------
        # Determine R53 change type
        # -----------------------
        route53_action = {
            "add": "CREATE",
            "update": "UPSERT",
            "delete": "DELETE"
        }[action]

        rrset = {
            "Name": fqdn,
            "Type": record_type,
            "TTL": ttl,
            "ResourceRecords": [{"Value": target_value}]
        }

        dns_change = {
            "Comment": f"Automated DNS {action} request",
            "Changes": [
                {
                    "Action": route53_action,
                    "ResourceRecordSet": rrset
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
                            "MetricName": "SuccessByAction",
                            "Dimensions": [
                                {"Name": "Action", "Value": action},
                            ],
                            "Value": 1,
                            "Unit": "Count",
                        },
                        {
                            "MetricName": "SuccessByClient",
                            "Dimensions": [
                                {"Name": "Client", "Value": client},
                            ],
                            "Value": 1,
                            "Unit": "Count",
                        },
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
                            "MetricName": "FailureByAction",
                            "Dimensions": [
                                {"Name": "Action", "Value": action},
                            ],
                            "Value": 1,
                            "Unit": "Count",
                        },
                        {
                            "MetricName": "FailureByClient",
                            "Dimensions": [
                                {"Name": "Client", "Value": client},
                            ],
                            "Value": 1,
                            "Unit": "Count",
                        },
                    ],
                )

            except Exception as metric_err:
                print("Metric write failed:", str(metric_err))

            raise ex

    return {"status": "ok", "message": "All SQS messages processed"}
