import json
import os
import boto3
import uuid
import logging

# Set up structured logging for CloudWatch
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Helper function to log structured JSON
def log_json(action, client, fqdn, target, status, error=None):
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


# boto3 client
route53 = boto3.client("route53")


def lambda_handler(event, context):
    print("Raw event:", json.dumps(event))

    hosted_zone_id = os.environ["HOSTED_ZONE_ID"]
    base_domain = os.environ["BASE_DOMAIN"]

    # SQS passes an array of records
    for record in event.get("Records", []):
        body = record.get("body")
        if not body:
            print("Empty message received, skipping.")
            continue

        try:
            msg = json.loads(body)
        except json.JSONDecodeError:
            print(f"Invalid JSON: {body}")
            continue

        print("Parsed message:", msg)

        # Required fields
        required_fields = [
            "action",
            "client",
            "source_env",
            "target_env",
            "record_type",
            "target_value"
        ]

        missing = [f for f in required_fields if f not in msg]
        if missing:
            raise ValueError(f"Missing required fields: {missing}")

        # Validate envs
        if msg["source_env"] != "staging":
            raise ValueError("source_env must be 'staging'")
        if msg["target_env"] != "production":
            raise ValueError("target_env must be 'production'")

        action = msg["action"]
        if action not in ["add", "update", "delete"]:
            raise ValueError(f"Invalid action: {action}")

        client = msg["client"]
        record_type = msg["record_type"]
        target_value = msg["target_value"]
        ttl = msg.get("ttl", 300)

        # Construct FQDN
        fqdn = f"{client}.{base_domain}".rstrip(".")
        print(f"FQDN resolved as: {fqdn}")

        # Map action to Route53 action
        route53_action = {
            "add": "CREATE",
            "update": "UPSERT",
            "delete": "DELETE"
        }[action]

        # Resource records
        if action == "delete":
            resource_records = []
        else:
            resource_records = [{"Value": target_value}]

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

        print(f"Submitting Route53 change: {json.dumps(dns_change)}")

        # Execute Route53 request
        try:
            response = route53.change_resource_record_sets(
                HostedZoneId=hosted_zone_id,
                ChangeBatch=dns_change
            )
            print("Route53 Response:", response)

            # ADD SUCCESS STRUCTURED LOG
            log_json(action, client, fqdn, target_value, "success")

        except Exception as ex:
            err = str(ex)
            print("Route53 Error:", err)

            # ADD FAILURE STRUCTURED LOG
            log_json(action, client, fqdn, target_value, "failure", err)

            raise ex

    return {"status": "ok", "message": "All SQS messages processed"}
