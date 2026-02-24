############################################
# envs/dev/variables.tf
############################################

variable "name" { type = string }
variable "tags" {
   type = map(string)
    default = {} 
    }

variable "vpc_cidr" {
  type    = string
  default = "10.10.0.0/16"
}

variable "app_port" {
  type    = number
  default = 8080
}

variable "health_check_path" {
  type    = string
  default = "/actuator/health"
}

variable "cors_allowed_origins" {
  type    = string
  default = "*"
}

# Artifact location (S3)
variable "app_s3_bucket" { type = string }
variable "app_s3_key" { type = string }

# Dev instance type
variable "dev_instance_type" {
  type    = string
  default = "t3.micro"
}

# DB settings
variable "db_name" { type = string }
variable "db_username" { type = string }
variable "db_password" {
  type      = string
  sensitive = true
}

# Optional alerts in dev
variable "notification_email" {
  description = "Email to receive CloudWatch alarms (optional in dev)"
  type        = string
  default     = null
}