import boto3
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

ec2 = boto3.client("ec2")

# Only manage instances that have this tag
TAG_KEY = "env"
TAG_VALUE = "dev"


def lambda_handler(event, context):
    action = event.get("action")
    logger.info("Received action: %s", action)

    filters = [
        {
            "Name": f"tag:{TAG_KEY}",
            "Values": [TAG_VALUE],
        }
    ]

    resp = ec2.describe_instances(Filters=filters)
    instance_ids = [
        inst["InstanceId"]
        for r in resp["Reservations"]
        for inst in r["Instances"]
        if inst["State"]["Name"] not in ["terminated", "shutting-down"]
    ]

    if not instance_ids:
        logger.info("No matching instances found")
        return {"message": "No matching instances found"}

    if action == "start":
        ec2.start_instances(InstanceIds=instance_ids)
        logger.info("Started instances: %s", instance_ids)
        return {"message": f"Started instances: {instance_ids}"}

    if action == "stop":
        ec2.stop_instances(InstanceIds=instance_ids)
        logger.info("Stopped instances: %s", instance_ids)
        return {"message": f"Stopped instances: {instance_ids}"}

    logger.error("Invalid action: %s", action)
    return {"error": "Invalid action, expected 'start' or 'stop'"}