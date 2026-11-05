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

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    sid     = "AllowLambdaServiceToAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}
resource "aws_iam_role" "lambda_execution" {
  name_prefix = "dbx-lambda-execution-"

  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = {
    Project     = "DBX Serverless Privilege Boundary Lab"
    Environment = "Lab"
    Purpose     = "Privileged Lambda execution role"
  }
}

data "aws_iam_policy_document" "lambda_s3_put" {
  statement {
    sid     = "AllowProtectedBucketPutObject"
    effect  = "Allow"
    actions = ["s3:PutObject"]

    resources = [
      "${aws_s3_bucket.protected.arn}/*"
    ]
  }
}

resource "aws_iam_role_policy" "lambda_s3_put" {
  name = "dbx-lambda-protected-s3-put"

  role   = aws_iam_role.lambda_execution.id
  policy = data.aws_iam_policy_document.lambda_s3_put.json
}
