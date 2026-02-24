############################################
# modules/observability/variables.tf
# Inputs for alarms, logs, dashboards, alerting
############################################

variable "name" {
  description = "Base name used for resources (e.g., geotechlab)"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
}

variable "tags" {
  description = "Common tags applied to resources"
  type        = map(string)
  default     = {}
}

# ----------------------------
# Alerting (SNS)
# ----------------------------
variable "alert_email" {
  description = "Email address to subscribe to alerts (set null to disable subscription)"
  type        = string
  default     = null
}

# ----------------------------
# Log Groups
# ----------------------------
variable "create_app_log_group" {
  description = "Whether to create a CloudWatch Log Group for the application"
  type        = bool
  default     = true
}

variable "app_log_group_name" {
  description = "Name of the application log group"
  type        = string
  default     = null
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days (prod often 30-90, dev often 7-14)"
  type        = number
  default     = 14
}

# ----------------------------
# Alarm Targets (IDs/Names)
# ----------------------------
variable "alb_arn_suffix" {
  description = "ALB ARN suffix required by CloudWatch metrics (e.g., app/my-alb/123abc...)"
  type        = string
  default     = null
}

variable "target_group_arn_suffix" {
  description = "Target Group ARN suffix required by CloudWatch metrics (e.g., targetgroup/my-tg/456def...)"
  type        = string
  default     = null
}

variable "asg_name" {
  description = "Auto Scaling Group name for EC2 CPU alarm dimension"
  type        = string
  default     = null
}

variable "rds_instance_id" {
  description = "RDS DB Instance Identifier for RDS alarms dimension"
  type        = string
  default     = null
}

# ----------------------------
# Alarm Tuning
# ----------------------------
variable "enable_alarms" {
  description = "Master switch to enable/disable alarms"
  type        = bool
  default     = true
}

variable "alarm_period_seconds" {
  description = "CloudWatch alarm evaluation period in seconds (commonly 60 or 300)"
  type        = number
  default     = 300
}

variable "alarm_evaluation_periods" {
  description = "Number of periods over which data is compared to the threshold"
  type        = number
  default     = 2
}

# ALB thresholds
variable "alb_5xx_threshold" {
  description = "Threshold for ALB HTTPCode_ELB_5XX_Count (sum per period)"
  type        = number
  default     = 10
}

variable "tg_5xx_threshold" {
  description = "Threshold for Target HTTPCode_Target_5XX_Count (sum per period)"
  type        = number
  default     = 10
}

variable "unhealthy_hosts_threshold" {
  description = "Threshold for UnHealthyHostCount (average per period)"
  type        = number
  default     = 1
}

# EC2 / ASG thresholds
variable "ec2_cpu_high_threshold" {
  description = "ASG average CPU utilization (%) above this triggers alarm"
  type        = number
  default     = 80
}

# RDS thresholds
variable "rds_cpu_high_threshold" {
  description = "RDS CPU utilization (%) above this triggers alarm"
  type        = number
  default     = 80
}

variable "rds_free_storage_bytes_low_threshold" {
  description = "RDS FreeStorageSpace below this (bytes) triggers alarm"
  type        = number
  # ~10 GiB default
  default     = 10 * 1024 * 1024 * 1024
}

# ----------------------------
# Dashboard
# ----------------------------
variable "create_dashboard" {
  description = "Whether to create a CloudWatch dashboard"
  type        = bool
  default     = true
}

############################################
# modules/observability/variables.tf
############################################

variable "system_log_group_name" {
  description = "CloudWatch log group name for system logs (/var/log/messages, /var/log/secure)"
  type        = string
  default     = null
}

variable "ec2_instance_id" {
  description = "EC2 instance ID for EC2 CPU alarms (used in dev when not using ASG)"
  type        = string
  default     = null
}