############################################
# modules/api_compute_ec2/main.tf
# Creates:
# - IAM role + instance profile
# - Attach policies: SSM + S3:GetObject + CloudWatchAgentServerPolicy
# - EC2 instance (AL2023) with user-data that installs CloudWatch Agent + runs Spring Boot JAR
############################################

locals {
  prefix = "${var.name}-${var.environment}"
}

# ----------------------------
# AMI: Amazon Linux 2023
# ----------------------------
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

# ----------------------------
# IAM Role for EC2
# ----------------------------
resource "aws_iam_role" "ec2_role" {
  name = "${local.prefix}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

# Allow SSM management (matches your diagram)
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Allow CloudWatch Agent to publish logs/metrics (observability requirement)
resource "aws_iam_role_policy_attachment" "cw_agent" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Minimal S3:GetObject for artifact download
resource "aws_iam_policy" "s3_get_object" {
  name        = "${local.prefix}-s3-get-object"
  description = "Allow EC2 to download the application JAR from S3"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = ["s3:GetObject"],
      Resource = [
        "arn:aws:s3:::${var.app_s3_bucket}/${var.app_s3_key}"
      ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "s3_get_object_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.s3_get_object.arn
}

# Instance Profile
resource "aws_iam_instance_profile" "profile" {
  name = "${local.prefix}-instance-profile"
  role = aws_iam_role.ec2_role.name
}

# ----------------------------
# User-data (templatefile)
# ----------------------------
locals {
  user_data = templatefile("${path.module}/user_data.sh", {
    NAME               = var.name
    ENVIRONMENT        = var.environment
    APP_S3_BUCKET      = var.app_s3_bucket
    APP_S3_KEY         = var.app_s3_key
    APP_PORT           = var.app_port
    CORS_ALLOWED_ORIGINS = var.cors_allowed_origins
    DB_HOST            = var.db_host
    DB_NAME            = var.db_name
    DB_USER            = var.db_username
    DB_PASS            = var.db_password
    CW_LOG_GROUP_APP   = var.cw_log_group_app
    CW_LOG_GROUP_SYS   = var.cw_log_group_sys
  })
}

# ----------------------------
# EC2 Instance
# ----------------------------
resource "aws_instance" "api" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  subnet_id                   = var.private_subnet_id
  vpc_security_group_ids      = [var.app_sg_id]
  iam_instance_profile        = aws_iam_instance_profile.profile.name
  associate_public_ip_address = false

  user_data = local.user_data

  tags = merge(var.tags, {
    Name = "${local.prefix}-api"
  })
}