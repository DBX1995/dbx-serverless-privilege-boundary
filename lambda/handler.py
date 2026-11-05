import os
import boto3

s3 = boto3.client("s3")

PROTECTED_BUCKET = os.environ["PROTECTED_BUCKET"]


def lambda_handler(event, context):
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
