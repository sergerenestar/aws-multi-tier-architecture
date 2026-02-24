############################
# Network
############################
module "network" {
  source = "./modules/network"

  name     = var.name
  vpc_cidr = var.vpc_cidr
  db_port  = 3306
}

############################
# Database (RDS MySQL)
############################
module "db" {
  source = "./modules/rds_mysql"

  name       = var.name
  vpc_id     = module.network.vpc_id
  subnet_ids = module.network.private_subnet_ids
  db_sg_id   = module.network.db_sg_id

  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password
}


############################
# Frontend (S3 + CloudFront)
############################
module "frontend" {
  source = "./modules/frontend_s3_cf"

  # Providers (CloudFront/WAF need us-east-1)
  providers = {
    aws      = aws
    aws.use1 = aws.use1
    random   = random
  }

  name                 = var.name
  aws_region           = var.aws_region
  force_destroy_bucket = true

  enable_waf             = var.enable_waf
  acm_cert_arn_us_east_1 = var.acm_cert_arn_us_east_1
  aliases                = var.aliases

  price_class         = var.price_class
  default_root_object = "index.html"
  cache_policy_id     = var.cache_policy_id
}

############################
# API (ALB + EC2 Spring Boot)
############################
module "api" {
  source = "./modules/api_ec2_alb"

  name               = var.name
  vpc_id             = module.network.vpc_id
  public_subnet_ids  = module.network.public_subnet_ids
  private_subnet_ids = module.network.private_subnet_ids

  app_sg_id = module.network.app_sg_id
  app_port  = var.app_port

  db_host     = module.db.db_host
  db_port     = module.db.db_port
  db_name     = module.db.db_name
  db_username = module.db.db_username
  db_password = var.db_password

  app_s3_bucket = var.app_s3_bucket
  app_s3_key    = var.app_s3_key
  

  # IMPORTANT: CORS locked to frontend CloudFront domain
  cors_allowed_origins = "https://${module.frontend.cloudfront_domain_name}"
}
