# Alarm Reconciliation — dbx-iam-privilege-change-detected

**Verdict:** Authorized lab change. No unauthorized activity.

| Item | Evidence |
|---|---|
| Alarm | OK → ALARM 2026-11-12 17:09:02 UTC; auto-cleared 17:24:02 UTC |
| Trigger event | CloudTrail `PutRolePolicy`, 17:05:45 UTC (only IAM write in window) |
| Principal | `iamadmin` via Terraform 1.16.2 / AWS provider 6.69.0 |
| Target | Role `dbx-low-privilege-caller-*`, inline policy `dbx-low-privilege-lambda-invoke` |
| Permission | `lambda:InvokeFunction` on `dbx-privileged-writer` only (no wildcards) |
| Source of truth | `iam.tf:84`, commit `fa7eef9` (2026-11-12 12:30 ET, after apply) |

**Conclusion:** Detection worked as designed. It caught the intentional
privilege grant that enabled the privilege-borrowing test, and the change
traces end-to-end: code → terraform apply → CloudTrail → CloudWatch alarm.