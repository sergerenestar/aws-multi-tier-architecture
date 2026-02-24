variable "name" {
  description = "Name prefix used for resources (e.g., serge-ng)"
  type        = string
}

variable "aws_region" {
  description = "Region for the S3 bucket (CloudFront is global)"
  type        = string
  default     = "us-east-2"
}

variable "force_destroy_bucket" {
  description = "Allow terraform destroy to delete bucket with objects"
  type        = bool
  default     = true
}

variable "enable_waf" {
  description = "Attach AWS WAFv2 (CloudFront scope)"
  type        = bool
  default     = false
}

variable "acm_cert_arn_us_east_1" {
  description = "ACM cert ARN in us-east-1 for custom domain on CloudFront. If null, uses default CloudFront cert."
  type        = string
  default     = null
}

variable "aliases" {
  description = "Optional custom domain names for CloudFront (requires acm_cert_arn_us_east_1)"
  type        = list(string)
  default     = []
}

variable "price_class" {
  description = "CloudFront price class"
  type        = string
  default     = "PriceClass_100"
}

variable "default_root_object" {
  description = "Default root object"
  type        = string
  default     = "index.html"
}

variable "cache_policy_id" {
  description = "Cache policy id for CloudFront. Default is AWS Managed-CachingOptimized."
  type        = string
  default     = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
}


