# DBX Serverless Privilege Boundary Lab

## Objective

Build a controlled AWS security lab that demonstrates how a low-privilege principal can indirectly cause a privileged AWS action by invoking a Lambda function whose execution role has greater permissions.

The lab will then implement defensive controls and verify that unauthorized indirect privilege use is blocked while legitimate use still works.

## Protected Resource

A synthetic Amazon S3 test bucket will be used as the protected resource.

The protected action will be:

`s3:PutObject`

No production data will be used.

## Low-Privilege Caller

The low-privilege caller will:

- NOT have direct permission to perform `s3:PutObject` on the protected test bucket
- have permission to invoke the intentionally vulnerable Lambda function

This identity represents the caller attempting to indirectly exercise privilege it does not possess directly.

## Privileged Lambda

The Lambda execution role will have permission to perform:

`s3:PutObject`

against the protected synthetic test bucket.

The function will initially accept a caller-controlled request and perform the protected action without sufficiently verifying whether the caller should be authorized to request it.

## Trust Boundary

```text
Caller-controlled request
        ↓
TRUST BOUNDARY
        ↓
Lambda application
        ↓
AWS SDK / boto3
        ↓
Protected S3 resource