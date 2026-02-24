############################################
# modules/api_compute_asg/variables.tf
# ASG compute for the API (Launch Template + Auto Scaling Group)
############################################

variable "name" { type = string }
variable "environment" { type = string }
variable "tags" {
  type = map(string)
   default = {}
   }

# Networking
variable "private_subnet_ids" {
  description = "Private subnets across at least 2 AZs for HA (prod best practice)"
  type        = list(string)
}

variable "app_sg_id" {
  description = "Security group ID for instances (app SG). ALB -> app ingress is handled in api_common_alb."
  type        = string
}

# Compute sizing
variable "instance_type" {
  description = "Instance type for API instances"
  type        = string
  default     = "t3.small"
}

variable "desired_capacity" {
  description = "Desired number of instances"
  type        = number
  default     = 2
}

variable "min_size" {
  description = "Minimum number of instances"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum number of instances"
  type        = number
  default     = 4
}

# App artifact
variable "app_s3_bucket" { type = string }
variable "app_s3_key" { type = string }

# Runtime
variable "app_port" { type = number }
variable "cors_allowed_origins" { type = string }

# DB
variable "db_host" { type = string }
variable "db_name" { type = string }
variable "db_username" { type = string }

variable "db_password" {
  type        = string
  sensitive   = true
  description = "DB password (prefer SSM/Secrets in prod)"
}

# Observability log groups
variable "cw_log_group_app" { type = string }
variable "cw_log_group_sys" { type = string }

# Target group attachment (ASG attaches itself to TG)
variable "target_group_arns" {
  description = "Target group ARNs to attach the ASG to (from api_common_alb.target_group_arn)"
  type        = list(string)
}