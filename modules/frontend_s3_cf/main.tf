# This module sets up a private S3 bucket to host frontend assets,
# and a CloudFront distribution to serve them securely with optional WAF protection.
#


# random suffix to ensure unique bucket name

resource "random_id" "suffix" {
  byte_length = 4
}


# -------------------------
# S3 bucket (private)
# -------------------------
resource "aws_s3_bucket" "frontend" {
  bucket        = "${var.name}-frontend-${random_id.suffix.hex}"
  force_destroy = var.force_destroy_bucket # allows terraform destroy to delete bucket even if it has objects (use with caution in prod!)
}

# enable bucket versioning for better data protection
resource "aws_s3_bucket_versioning" "ver" {
  bucket = aws_s3_bucket.frontend.id
  versioning_configuration {
    status = "Enabled"
  }
}
#  block all public access to the bucket
resource "aws_s3_bucket_public_access_block" "pab" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# enforce bucket owner ownership
resource "aws_s3_bucket_ownership_controls" "own" {
  bucket = aws_s3_bucket.frontend.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# -------------------------
# CloudFront OAC (Origin Access Control) for S3
# this is the modern replacement for OAI, allowing secure access to private S3 buckets without needing to manage IAM permissions for CloudFront's OAI user.
# OACs vs OAIs: https://aws.amazon.com/blogs/networking-and-content-delivery/introducing-origin-access-control-for-amazon-cloudfront/
# https://repost.aws/questions/QUY3prSJX-QMS-0UtwtmbeMQ/cloudfront-oac-s3-public-reads-only-signed-secure-writes

# -------------------------
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "${var.name}-oac"
  description                       = "OAC for S3 origin"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# -------------------------
# Optional WAF (CLOUDFRONT scope, must be us-east-1)
# -------------------------
resource "aws_wafv2_web_acl" "waf" {
  provider = aws.use1
  count    = var.enable_waf ? 1 : 0

  name  = "${var.name}-waf"
  scope = "CLOUDFRONT"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.name}-waf"
    sampled_requests_enabled   = true
  }

  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.name}-common-rules"
      sampled_requests_enabled   = true
    }
  }
}

# -------------------------
# CloudFront Distribution
# -------------------------
resource "aws_cloudfront_distribution" "cdn" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Frontend CDN"
  default_root_object = var.default_root_object
  price_class         = var.price_class

  # Optional: add custom domain aliases
  aliases = var.acm_cert_arn_us_east_1 == null ? null : var.aliases

  origin {
    domain_name              = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_id                = "s3-frontend"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  default_cache_behavior {
    target_origin_id       = "s3-frontend"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD", "OPTIONS"]

    cache_policy_id = var.cache_policy_id

    compress = true
  }

  # ✅ SPA refresh fix: /todos -> index.html
  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 0
  }

  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 0
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    # If you provide ACM cert in us-east-1, CloudFront will use it.
    acm_certificate_arn            = var.acm_cert_arn_us_east_1
    ssl_support_method             = var.acm_cert_arn_us_east_1 == null ? null : "sni-only"
    minimum_protocol_version       = "TLSv1.2_2021"
    cloudfront_default_certificate = var.acm_cert_arn_us_east_1 == null ? true : false
  }

  web_acl_id = var.enable_waf ? aws_wafv2_web_acl.waf[0].arn : null
}

# -------------------------
# Bucket policy: allow CloudFront (OAC) to read objects
# -------------------------
data "aws_iam_policy_document" "bucket_policy" {
  statement {
    sid     = "AllowCloudFrontRead"
    actions = ["s3:GetObject"]

    resources = ["${aws_s3_bucket.frontend.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.cdn.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "allow_cf" {
  bucket = aws_s3_bucket.frontend.id
  policy = data.aws_iam_policy_document.bucket_policy.json
}
