import json
import os
import boto3
import uuid
import logging

# -----------------------
# Logging setup (AC3)
# -----------------------
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS Clients
route53 = boto3.client("route53")
cloudwatch = boto3.client("cloudwatch")

def log_json(action, client, fqdn, target, status, error=None):
    """Structured JSON logging for CloudWatch Logs (AC3 Requirement)"""
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

def emit_metrics(status_type, client, action):
    """
    Reports a single consistent metric with dual dimensions.
    This allows Grafana to aggregate (Sum) the data for any filter combination.
    """
    namespace = "ClientDomainSystem"
    # Unified metric name: SuccessCount or FailureCount
    metric_name = f"{status_type}Count" 
    
    try:
        cloudwatch.put_metric_data(
            Namespace=namespace,
            MetricData=[
                {
                    "MetricName": metric_name,
                    "Dimensions": [
                        {"Name": "Client", "Value": client},
                        {"Name": "Action", "Value": action}
                    ],
                    "Value": 1,
                    "Unit": "Count"
                }
            ]
        )
    except Exception as e:
        print(f"Failed to emit metrics: {str(e)}")
        
def safe_log_error(msg, raw_payload=None):
    """Logs error and emits failure metrics before raising exception for SQS/DLQ"""
    client = "unknown"
    action = "unknown"
    
    if isinstance(raw_payload, dict):
        client = raw_payload.get("client", "unknown")
        action = raw_payload.get("action", "unknown")

    log_json(
        action=action,
        client=client,
        fqdn="unknown",
        target=str(raw_payload),
        status="failure",
        error=msg
    )
    
    emit_metrics("Failure", client, action)

def lambda_handler(event, context):
    """
    Main entry point for SQS Trigger (AC1 & AC2)
    """
    print("Raw event:", json.dumps(event))
    hosted_zone_id = os.environ["HOSTED_ZONE_ID"]
    base_domain = os.environ["BASE_DOMAIN"]

    for record in event.get("Records", []):
        body = record.get("body")
        if not body:
            safe_log_error("Empty message received")
            raise ValueError("Empty SQS message")

        # 1. Parse JSON (AC1)
        try:
            msg = json.loads(body)
        except json.JSONDecodeError as e:
            safe_log_error(f"JSON decode error: {str(e)}", body)
            raise e

        # 2. Validate Schema (AC1)
        required = ["action", "client", "source_env", "target_env", "record_type", "target_value"]
        missing = [f for f in required if f not in msg]
        if missing:
            safe_log_error(f"Missing fields: {missing}", msg)
            raise ValueError(f"Payload missing fields: {missing}")

        # 3. Environment & Action Logic
        if msg["source_env"] != "staging" or msg["target_env"] != "production":
            safe_log_error("Invalid environment routing", msg)
            raise ValueError("Logic Error: source_env must be staging and target_env must be production")

        action = msg["action"]
        client = msg["client"]
        record_type = msg["record_type"]
        target_value = msg["target_value"]
        ttl = msg.get("ttl", 300)

        if action not in ["add", "update", "delete"]:
            safe_log_error(f"Invalid action type: {action}", msg)
            raise ValueError(f"Unsupported action: {action}")

        # 4. Compute FQDN (AC2)
        fqdn = f"{client}.production.{base_domain}".rstrip(".")
        route53_action = {"add": "CREATE", "update": "UPSERT", "delete": "DELETE"}[action]

        dns_change = {
            "Comment": f"Automated DNS {action} request",
            "Changes": [{
                "Action": route53_action,
                "ResourceRecordSet": {
                    "Name": fqdn,
                    "Type": record_type,
                    "TTL": ttl,
                    "ResourceRecords": [{"Value": target_value}]
                }
            }]
        }

        # 5. Execute Route 53 Change (AC2)
        try:
            route53.change_resource_record_sets(
                HostedZoneId=hosted_zone_id,
                ChangeBatch=dns_change
            )
            # AC3 Logging
            log_json(action, client, fqdn, target_value, "success")
            # AC4 Metrics
            emit_metrics("Success", client, action)

        except Exception as ex:
            # If Route 53 fails (e.g., rate limit or invalid target), 
            # log failure, record metric, and raise to trigger SQS retry/DLQ
            safe_log_error(str(ex), msg)
            raise ex

    return {"status": "ok", "message": "All messages processed successfully"}