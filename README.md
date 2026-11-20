# Serverless Privilege Boundary Lab (AWS)

Least-privilege IAM is not enough on its own. A low-privilege identity that is denied a
protected action can still get a **more-privileged service** to perform it on its behalf
(privilege borrowing, also called a confused-deputy problem). This lab shows the gap,
closes it with an application-layer authorization gate, and verifies every claim at runtime.

**Stack:** AWS IAM · STS · Lambda · S3 · CloudTrail · CloudWatch · Terraform · Python/boto3

## Results (runtime-verified)

| # | Path | Result |
|---|---|---|
| 1 | Low-privilege caller → S3 `PutObject` directly | **DENIED** (IAM) |
| 2 | Low-privilege caller → Lambda → S3 *(vulnerable)* | **SUCCESS**, privilege borrowed |
| 3 | Caller → Lambda, **no token** *(defended)* | **DENIED**, no S3 object created |
| 4 | Caller → Lambda, **wrong token** *(defended)* | **DENIED**, no S3 object created |
| 5 | Caller → Lambda, **valid token** *(defended)* | **SUCCESS**, object written |

All tests ran as the low-privilege role via STS `AssumeRole`. Side effects (or their absence)
were verified independently with an admin identity listing the bucket.

## Architecture

```text
Low-privilege caller ──X──> Protected S3 bucket          (IAM denies direct write)

Low-privilege caller ──> lambda:InvokeFunction ──> Privileged Lambda ──> s3:PutObject
                                                         │
                                               Authorization gate
                                          (runs before any S3 side effect)
```

## Key insight

**IAM authorization and application authorization are different layers.**
IAM decides who can *invoke* the Lambda. Only the Lambda's code can decide whether a given
request should be allowed to *use* the Lambda's privileges. Fixing the IAM policy on the
Lambda's execution role would not close this gap; the gap is in who can reach it.

## The defense (`lambda/handler.py`)

- **Fail closed:** missing configured token, malformed event, missing token, or wrong
  token → deny. Exactly one code path returns allow.
- **Gate before side effect:** authorization runs before `s3.put_object()`.
- **Constant-time comparison:** `hmac.compare_digest` avoids timing side channels.
- **No secrets in source:** the token is supplied through a `sensitive` Terraform variable
  (`TF_VAR_authorization_token`), generated per session from a CSPRNG, and never committed.
- **Denials are logged** to CloudWatch Logs (without the token value).

## Detection and investigation

An account-level CloudWatch alarm on IAM privilege changes fired when the lab granted the
caller `lambda:InvokeFunction`. Rather than dismissing it as "probably the lab," it was
traced end to end: alarm → CloudTrail `PutRolePolicy` → principal, tool, and policy
document → Terraform source line → Git commit.
See [`docs/alarm-reconciliation.md`](docs/alarm-reconciliation.md).

## What this does NOT prove (limitations)

- A **shared static token** is lab-grade. Production designs should authorize on verified
  caller identity (e.g., IAM-authenticated front door with per-caller authorization) and
  keep secrets in AWS Secrets Manager with rotation.
- The token lives in the Lambda's environment (readable by anyone with
  `lambda:GetFunctionConfiguration`) and in **Terraform state in plaintext**. State is
  excluded from Git; a real deployment would use an encrypted, access-controlled remote backend.
- Single account, synthetic data, one Lambda. The alarm was validated against one IAM event type.

## Repository layout

| Path | Purpose |
|---|---|
| `main.tf`, `providers.tf` | Protected S3 bucket (encryption, public access block) and provider config |
| `iam.tf` | Low-privilege caller role, Lambda execution role, scoped policies |
| `lambda.tf`, `variables.tf` | Lambda function and sensitive token variable |
| `lambda/handler.py` | Privileged writer with authorization gate |
| `SECURITY_SCOPE.md` | Lab scope and boundaries |
| `docs/alarm-reconciliation.md` | Alarm investigation evidence |

## Reproduce

```powershell
# Package the Lambda (handler.py must be at the zip root)
Compress-Archive -Path lambda\handler.py -DestinationPath lambda_package.zip -Force

# Session-only token (never printed, never committed)
$b = New-Object byte[] 32
[Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($b)
$env:TF_VAR_authorization_token = [Convert]::ToBase64String($b)

terraform init
terraform plan
terraform apply
```

Then assume the low-privilege role and invoke the Lambda with no token, a wrong token,
and the valid token; verify bucket contents as an admin. Tear down with `terraform destroy`.