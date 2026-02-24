############################################
# Global / Naming
############################################
variable "name" {
  description = "Name prefix for all resources (e.g., geolab)"
  type        = string
}

############################################
# AWS Provider Config
############################################
variable "aws_profile" {
  description = "AWS CLI profile Terraform should use"
  type        = string
  default     = "sergeadmin"
}

variable "aws_region" {
  description = "Primary AWS region for regional resources (S3, VPC, EC2, RDS)"
  type        = string
  default     = "us-east-2"
}

############################################
# Network
############################################
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.50.0.0/16"
}

############################################
# Database (RDS MySQL)
############################################
variable "db_name" {
  description = "Database name to create inside RDS"
  type        = string
  default     = "geotech"
}

variable "db_username" {
  description = "Master username for RDS"
  type        = string
  default     = "geotechadmin"
}

variable "db_password" {
  description = "Master password for RDS (keep secret)"
  type        = string
  sensitive   = true
}

############################################
# API (Spring Boot on EC2)
############################################
variable "app_port" {
  description = "Port Spring Boot listens on (inside EC2)"
  type        = number
  default     = 8080
}

variable "app_s3_bucket" {
  description = "S3 bucket that stores the Spring Boot JAR"
  type        = string
}

variable "app_s3_key" {
  description = "S3 object key for the Spring Boot JAR (e.g., releases/geolab-api.jar)"
  type        = string
}

# Keep this variable if you want manual override.
# If you always want it derived from CloudFront, you can remove it.
variable "cors_allowed_origins" {
  description = "CORS allowed origin(s) for the API. Usually the CloudFront URL."
  type        = string
  default     = "*"
}

############################################
# Frontend (S3 + CloudFront)
############################################
variable "enable_waf" {
  description = "Attach AWS WAFv2 to CloudFront (scope CLOUDFRONT, us-east-1)"
  type        = bool
  default     = false
}

variable "acm_cert_arn_us_east_1" {
  description = "ACM certificate ARN in us-east-1 for CloudFront custom domain. Null = default CF cert."
  type        = string
  default     = null
}

variable "aliases" {
  description = "CloudFront custom domain aliases (requires acm_cert_arn_us_east_1)"
  type        = list(string)
  default     = []
}

variable "price_class" {
  description = "CloudFront price class"
  type        = string
  default     = "PriceClass_100"
}

variable "cache_policy_id" {
  description = "CloudFront cache policy ID"
  type        = string
  default     = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
}

variable "notification_email" {
  description = "Email to receive CloudWatch alarm notifications via SNS"
  type        = string
  default     = null
}
