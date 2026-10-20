data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "low_privilege_assume_role" {
  statement {
    sid     = "AllowCurrentIdentityToAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = [data.aws_caller_identity.current.arn]
    }
  }
}

resource "aws_iam_role" "low_privilege_caller" {
  name_prefix = "dbx-low-privilege-caller-"

  assume_role_policy = data.aws_iam_policy_document.low_privilege_assume_role.json

  tags = {
    Project     = "DBX Serverless Privilege Boundary Lab"
    Environment = "Lab"
    Purpose     = "Synthetic low-privilege caller"
  }
}
