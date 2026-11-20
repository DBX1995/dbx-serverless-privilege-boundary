resource "aws_lambda_function" "privileged_writer" {
  function_name = "dbx-privileged-writer"

  filename         = "${path.module}/lambda_package.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda_package.zip")

  role    = aws_iam_role.lambda_execution.arn
  handler = "handler.lambda_handler"
  runtime = "python3.13"

  environment {
    variables = {
      PROTECTED_BUCKET    = aws_s3_bucket.protected.bucket
      AUTHORIZATION_TOKEN = var.authorization_token
    }
  }

  tags = {
    Project     = "DBX Serverless Privilege Boundary Lab"
    Environment = "Lab"
    Purpose     = "Privileged synthetic S3 writer"
  }
}
