import json
import os
import boto3

#boto 3 is python SDK provided by amazon
#so python can visit AWS service
#a service side that can control (by action) route53
route53 = boto3.client("route53")

#the function will run if trigger lambda
#and the parameter that will pass inside
def lambda_handler(event, context):
    print("Raw event:", json.dumps(event))
    #the hosted zone and based domain for route 53
    hosted_zone_id = os.environ["HOSTED_ZONE_ID"]
    base_domain = os.environ["BASE_DOMAIN"]

    # SQS always sends a list of Records
    for record in event.get("Records", []):
        #get the messsage body that need to be processed
        body = record.get("body")
        if not body:
            print("Empty message received, skipping.")
            continue

        try:
            #the body need to be json
            msg = json.loads(body)
        except json.JSONDecodeError:
            print(f"Invalid JSON: {body}")
            continue

        print("Parsed message:", msg)

        # Validate required fields
        required_fields = [
            "action", #action
            "client", #client name
            "source_env", #staging 
            "target_env", #production
            "record_type", # A (ip) or cname (dns)
            "target_value" #the ip or dns that fqdn should point to 
        ]
        #error if missing required fields
        missing = [f for f in required_fields if f not in msg]
        if missing:
            raise ValueError(f"Missing required fields: {missing}")

        # Ensure envs match schema
        if msg["source_env"] != "staging":
            raise ValueError("source_env must be 'staging'")
        if msg["target_env"] != "production":
            raise ValueError("target_env must be 'production'")

        # Validate DNS action
        action = msg["action"]
        if action not in ["add", "update", "delete"]:
            raise ValueError(f"Invalid action: {action}")

        client = msg["client"]
        record_type = msg["record_type"]
        target_value = msg["target_value"]
        #optional and default is 300
        ttl = msg.get("ttl", 300)

        # Construct final FQDN:
        # production domain output
        fqdn = f"{client}.{base_domain}".rstrip(".")
        print(f"FQDN resolved as: {fqdn}")

        # Map action to Route53
        route53_action = {
            "add": "CREATE",
            "update": "UPSERT",
            "delete": "DELETE"
        }[action]

        # Only delete does not require a target_value
        # resource records is the dns record which consist of 
        # name and value (the fqdn and its target)
        # add and update need to have new resource records
        #but delete will just make it empty
        if action == "delete":
            resource_records = []
        else:
            resource_records = [{"Value": target_value}]

        #the final message that will send to route53 in JSON
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

        # send the message to route 53 in that hosted zone 
        try:
            response = route53.change_resource_record_sets(
                HostedZoneId=hosted_zone_id,
                ChangeBatch=dns_change
            )
            print("Route53 Response:", response)
        except Exception as ex:
            print("Route53 Error:", str(ex))
            raise ex

    return {"status": "ok", "message": "All SQS messages processed"}
