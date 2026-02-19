# S3 bucket to store application artifacts (e.g., Spring Boot JARs/zips).
# Bucket name is provided via variables so this repo is safe to share publicly.

resource "aws_s3_bucket" "artifacts" {
  bucket = var.artifacts_bucket_name

  lifecycle {
    # Protect prod buckets from accidental deletion
    prevent_destroy = var.environment == "prod"
  }

  tags = {
    Name        = "geolab-artifacts-${var.environment}"
    Purpose     = "spring-boot-artifacts"
    Environment = var.environment
  }
}


resource "aws_s3_bucket_versioning" "artifacts_versioning" {
  bucket = aws_s3_bucket.artifacts.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "artifacts_encryption" {
  bucket = aws_s3_bucket.artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
