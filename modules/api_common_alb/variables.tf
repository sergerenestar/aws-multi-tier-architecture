############################################
# modules/api_common_alb/variables.tf
# ALB + Target Group shared by EC2 and ASG compute modules
############################################

variable "name" {
  description = "Base name for resources (e.g., geotechlab)"
  type        = string
}

variable "environment" {
  description = "Environment name (dev/prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where ALB and target group live"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnets for ALB (usually 2 across AZs)"
  type        = list(string)
}

variable "app_sg_id" {
  description = "Security group ID for the application (EC2/ASG instances). ALB-to-app ingress is allowed here."
  type        = string
}

variable "app_port" {
  description = "Port the application listens on (target group forwards to this port)"
  type        = number
}

variable "health_check_path" {
  description = "HTTP path for ALB target group health checks"
  type        = string
  default     = "/actuator/health"
}

variable "alb_listener_port" {
  description = "Public listener port on the ALB (HTTP)"
  type        = number
  default     = 80
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}