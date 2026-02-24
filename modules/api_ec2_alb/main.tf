############################################
# modules/api_ec2_alb/main.tf
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

# 2) EC2 compute
module "compute" {
  source = "../api_compute_ec2"

  name         = var.name
  environment  = var.environment
  tags         = var.tags

  private_subnet_id = var.private_subnet_id
  app_sg_id         = var.app_sg_id
  instance_type     = var.instance_type

  app_s3_bucket       = var.app_s3_bucket
  app_s3_key          = var.app_s3_key
  app_port            = var.app_port
  cors_allowed_origins = var.cors_allowed_origins

  db_host     = var.db_host
  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password

  cw_log_group_app = var.cw_log_group_app
  cw_log_group_sys = var.cw_log_group_sys
}

# 3) Attach the EC2 instance to the shared Target Group
resource "aws_lb_target_group_attachment" "ec2" {
  target_group_arn = module.common.target_group_arn
  target_id        = module.compute.instance_id
  port             = var.app_port
}