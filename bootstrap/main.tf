# -------------------------
# Terraform Remote State Backend (Bootstrap)
# Creates:
# - S3 bucket for Terraform state (private, versioned, encrypted)
# - DynamoDB table for state locking
# -------------------------

# S3 bucket for Terraform state (name passed via variables to keep repo public-safe)
resource "aws_s3_bucket" "tf_state" {
  bucket = var.tf_state_bucket_name

  lifecycle {
    # Protect remote state bucket from accidental deletion
    prevent_destroy = true
  }

  tags = {
    Name        = "terraform-state"
    Environment = "global"
  }
}

# Block all public access (required for state bucket)
resource "aws_s3_bucket_public_access_block" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning to keep history of state changes
resource "aws_s3_bucket_versioning" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Encrypt state at rest
# Option A (simple): SSE-S3 with AES256 (no extra KMS request cost)
resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# -------------------------
# DynamoDB table for state locking
# Prevents concurrent state modifications
# -------------------------
resource "aws_dynamodb_table" "tf_lock" {
  name         = var.tf_lock_table_name
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
