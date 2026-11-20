import hmac
import os
import boto3

s3 = boto3.client("s3")

PROTECTED_BUCKET = os.environ["PROTECTED_BUCKET"]
AUTHORIZATION_TOKEN = os.environ.get("AUTHORIZATION_TOKEN", "")


def is_authorized(event):
    # Fail closed: no configured token, bad event, or bad token -> deny
    if not AUTHORIZATION_TOKEN or not isinstance(event, dict):
        return False
    supplied = event.get("authorization_token")
    if not isinstance(supplied, str):
        return False
    return hmac.compare_digest(supplied.encode(), AUTHORIZATION_TOKEN.encode())


def lambda_handler(event, context):
    # Authorization gate runs BEFORE any S3 side effect
    if not is_authorized(event):
        print("DENIED: missing or invalid authorization token")
        return {"status": "denied"}

    key = event["key"]
    content = event["content"]

    s3.put_object(
        Bucket=PROTECTED_BUCKET,
        Key=key,
        Body=content
    )

    return {
        "status": "success",
        "key": key
    }