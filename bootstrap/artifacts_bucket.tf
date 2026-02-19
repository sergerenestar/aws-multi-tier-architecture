# This file defines an S3 bucket resource named "artifacts" that will be used to store Spring Boot artifacts.
# The bucket is tagged with metadata for identification and management purposes.
resource "aws_s3_bucket" "artifacts" {
  bucket = "geolab-artifacts-191303961254"

  lifecycle {
    prevent_destroy = false
  }

  tags = {
    Name        = "geolab-artifacts"
    Purpose     = "spring-boot-artifacts"
    Environment = "dev"
  }
}