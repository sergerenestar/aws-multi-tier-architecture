############################################
# modules/api_compute_ec2/variables.tf
# EC2 compute with IAM + user-data observability
############################################

variable "name" { type = string }
variable "environment" { type = string }
variable "tags" { 
  type = map(string) 
  default = {} 
  }

variable "private_subnet_id" {
  description = "One private subnet where the EC2 instance will be placed (dev is often single-AZ)"
  type        = string
}

variable "app_sg_id" {
  description = "Security group for the EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for API"
  type        = string
  default     = "t3.micro"
}

# ---------- App artifact ----------
variable "app_s3_bucket" { type = string }
variable "app_s3_key" { type = string }

# ---------- Runtime ----------
variable "app_port" { type = number }
variable "cors_allowed_origins" { type = string }

# ---------- DB ----------
variable "db_host" { type = string }
variable "db_name" { type = string }
variable "db_username" { type = string }

# In prod, prefer pulling this from SSM/Secrets Manager rather than tfvars.
variable "db_password" {
  type        = string
  sensitive   = true
  description = "DB password (consider using SSM/Secrets Manager instead of tfvars)"
}

# ---------- Observability ----------
variable "cw_log_group_app" {
  description = "CloudWatch Log Group name for application logs"
  type        = string
}

variable "cw_log_group_sys" {
  description = "CloudWatch Log Group name for system logs"
  type        = string
}