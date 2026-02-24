############################################
# envs/dev/main.tf
# Dev deployment:
# - API = api_ec2_alb (EC2 + ALB)
# - Observability = CloudWatch logs + alarms (EC2-based CPU alarm)
############################################

locals {
  environment      = "dev"
  cw_log_group_app = "/aws/${var.name}/${local.environment}/app"
  cw_log_group_sys = "/aws/${var.name}/${local.environment}/system"
}

# ----------------------------
# Network (example)
# ----------------------------
module "vpc" {
  source = "../../modules/vpc"

  name        = var.name
  environment = local.environment
  cidr_block  = var.vpc_cidr
  az_count    = 2

  tags = var.tags
}

# ----------------------------
# Security Groups (example)
# App SG must exist before api_common_alb can add "ALB -> App" ingress
# ----------------------------
module "security" {
  source = "../../modules/security"

  name        = var.name
  environment = local.environment
  vpc_id      = module.vpc.vpc_id
  tags        = var.tags

  # If your security module needs these:
  app_port = var.app_port
}

# ----------------------------
# Database (example)
# If dev uses RDS: keep it small/single-AZ
# If dev uses no DB: you can still wire to shared DB or mock.
# ----------------------------
module "db" {
  source = "../../modules/rds"

  name        = var.name
  environment = local.environment
  vpc_id      = module.vpc.vpc_id
  subnet_ids  = module.vpc.private_subnet_ids

  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password

  # Dev-friendly settings (example)
  instance_class          = "db.t3.micro"
  multi_az                = false
  backup_retention_period = 1
  deletion_protection     = false

  tags = var.tags
}

# ----------------------------
# API (DEV) = EC2 + ALB (composed from api_common_alb + api_compute_ec2)
# ----------------------------
module "api" {
  source = "../../modules/api_ec2_alb"

  name        = var.name
  environment = local.environment
  tags        = var.tags

  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids

  # Dev uses a single private subnet (cheap/simple)
  private_subnet_id = module.vpc.private_subnet_ids[0]

  app_sg_id = module.security.app_sg_id
  app_port  = var.app_port

  health_check_path = var.health_check_path

  # Artifact
  app_s3_bucket = var.app_s3_bucket
  app_s3_key    = var.app_s3_key

  # Runtime
  cors_allowed_origins = var.cors_allowed_origins
  instance_type        = var.dev_instance_type

  # DB wiring
  db_host     = module.db.endpoint
  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password

  # Observability log groups (Terraform creates them; agent ships to them)
  cw_log_group_app = local.cw_log_group_app
  cw_log_group_sys = local.cw_log_group_sys
}

# ----------------------------
# Observability (DEV) = logs + alarms
# Use EC2 instance ID for CPU alarm
# ----------------------------
module "observability" {
  source = "../../modules/observability"

  name        = var.name
  environment = local.environment
  tags        = var.tags

  # Alerts (optional in dev)
  alert_email = var.notification_email

  # Log groups
  create_app_log_group  = true
  app_log_group_name    = local.cw_log_group_app
  system_log_group_name = local.cw_log_group_sys

  # Dev retention smaller (cost)
  log_retention_days = 7

  # ALB/TG alarms still apply in dev
  alb_arn_suffix          = module.api.alb_arn_suffix
  target_group_arn_suffix = module.api.target_group_arn_suffix

  # Dev-specific CPU alarm uses the single instance ID
  ec2_instance_id = module.api.instance_id

  # Dev tuning (less noisy)
  alarm_period_seconds      = 300
  alarm_evaluation_periods  = 2
  alb_5xx_threshold         = 25
  tg_5xx_threshold          = 25
  unhealthy_hosts_threshold = 1
  ec2_cpu_high_threshold    = 85

  create_dashboard = true
}

# ----------------------------
# Useful outputs
# ----------------------------
output "dev_api_url" {
  value = "http://${module.api.alb_dns_name}"
}