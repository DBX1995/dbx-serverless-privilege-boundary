resource "aws_s3_bucket" "protected" {
  bucket_prefix = "dbx-privilege-boundary-protected-"

  tags = {
    Project     = "DBX Serverless Privilege Boundary Lab"
    Environment = "Lab"
    Purpose     = "Synthetic protected resource"
  }
}

resource "aws_s3_bucket_public_access_block" "protected" {
  bucket = aws_s3_bucket.protected.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "protected" {
  bucket = aws_s3_bucket.protected.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
