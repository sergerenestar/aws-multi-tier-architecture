############################################
# modules/api_asg_alb/main.tf
# Compose:
# - api_common_alb (ALB + TG + ALB SG + ALB->App rule)
# - api_compute_asg (LT + ASG attached to TG)
############################################

# 1) Common ALB + Target Group
module "common" {
  source = "../api_common_alb"

  name              = var.name
  environment       = var.environment
  vpc_id            = var.vpc_id
  public_subnet_ids = var.public_subnet_ids

  app_sg_id         = var.app_sg_id
  app_port          = var.app_port
  health_check_path = var.health_check_path

  tags = var.tags
}

# 2) ASG Compute (attaches to TG)
module "compute" {
  source = "../api_compute_asg"

  name        = var.name
  environment = var.environment
  tags        = var.tags

  private_subnet_ids = var.private_subnet_ids
  app_sg_id          = var.app_sg_id

  instance_type     = var.instance_type
  desired_capacity  = var.desired_capacity
  min_size          = var.min_size
  max_size          = var.max_size

  app_s3_bucket        = var.app_s3_bucket
  app_s3_key           = var.app_s3_key
  app_port             = var.app_port
  cors_allowed_origins = var.cors_allowed_origins

  db_host     = var.db_host
  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password

  cw_log_group_app = var.cw_log_group_app
  cw_log_group_sys = var.cw_log_group_sys

  # Attach ASG to the Target Group created in api_common_alb
  target_group_arns = [module.common.target_group_arn]
}