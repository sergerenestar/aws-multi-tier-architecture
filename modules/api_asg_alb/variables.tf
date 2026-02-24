############################################
# modules/api_asg_alb/variables.tf
# Wrapper that composes:
# - api_common_alb
# - api_compute_asg
############################################

variable "name" { type = string }
variable "environment" { type = string }
variable "tags" { 
  type = map(string) 
  default = {} 
  }

# Networking (common ALB)
variable "vpc_id" { type = string }
variable "public_subnet_ids" { type = list(string) }

# Networking (compute)
variable "private_subnet_ids" {
  description = "Private subnets across at least 2 AZs for HA"
  type        = list(string)
}

variable "app_sg_id" { type = string }
variable "app_port" { type = number }

variable "health_check_path" {
  type    = string
  default = "/actuator/health"
}

# Compute sizing
variable "instance_type" {
  type    = string
  default = "t3.small"
}

variable "desired_capacity" {
  type    = number
  default = 2
}

variable "min_size" {
  type    = number
  default = 2
}

variable "max_size" {
  type    = number
  default = 4
}

# Artifact + runtime + DB
variable "app_s3_bucket" { type = string }
variable "app_s3_key" { type = string }
variable "cors_allowed_origins" { type = string }

variable "db_host" { type = string }
variable "db_name" { type = string }
variable "db_username" { type = string }
variable "db_password" { 
  type = string 
  sensitive = true 
}

# Observability log groups
variable "cw_log_group_app" { type = string }
variable "cw_log_group_sys" { type = string }