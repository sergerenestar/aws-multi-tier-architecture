# -------------------------
# S3 bucket for Terraform state
# -------------------------
resource "aws_s3_bucket" "tf_state" {
  bucket = "serge-tfstate-191303961254"

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name        = "terraform-state"
    Environment = "global"
  }
}

#Block for public access
# since rhis reurce will be storing Terraform state, the public access is block ensuring that the bucket is not publicly accessible.
resource "aws_s3_bucket_public_access_block" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#enabling versioning on the S3 bucket to maintain a history of changes
resource "aws_s3_bucket_versioning" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  versioning_configuration {
    status = "Enabled"
  }
}
#  Encrypting the S3 bucket using AWS KMS to ensure that the Terraform state files are securely stored.
resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "AES256"

    }
  }
}


 #-------------------------
# DynamoDB table for state locking
# this resource creates a DynamoDB table that Terraform will use for state locking, preventing concurrent modifications to the state file and ensuring consistency during Terraform operations.
# -------------------------
resource "aws_dynamodb_table" "tf_lock" {
  name         = "terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "terraform-locks"
    Environment = "global"
  }
}

