############################################
# modules/api_compute_asg/main.tf
# Creates:
# - IAM role + instance profile
# - Launch Template with user-data
# - Auto Scaling Group attached to target group(s)
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
# IAM Role for ASG instances
# ----------------------------
resource "aws_iam_role" "ec2_role" {
  name = "${local.prefix}-asg-ec2-role"

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

# SSM for admin access / troubleshooting
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# CloudWatch Agent logs + metrics
resource "aws_iam_role_policy_attachment" "cw_agent" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Minimal S3:GetObject for JAR download
resource "aws_iam_policy" "s3_get_object" {
  name        = "${local.prefix}-asg-s3-get-object"
  description = "Allow ASG instances to download the application JAR from S3"

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

resource "aws_iam_instance_profile" "profile" {
  name = "${local.prefix}-asg-instance-profile"
  role = aws_iam_role.ec2_role.name
}

# ----------------------------
# User-data template
# ----------------------------
locals {
  user_data = templatefile("${path.module}/user_data.sh", {
    NAME                = var.name
    ENVIRONMENT         = var.environment
    APP_S3_BUCKET       = var.app_s3_bucket
    APP_S3_KEY          = var.app_s3_key
    APP_PORT            = var.app_port
    CORS_ALLOWED_ORIGINS = var.cors_allowed_origins
    DB_HOST             = var.db_host
    DB_NAME             = var.db_name
    DB_USER             = var.db_username
    DB_PASS             = var.db_password
    CW_LOG_GROUP_APP    = var.cw_log_group_app
    CW_LOG_GROUP_SYS    = var.cw_log_group_sys
  })
}

# Launch Template expects base64 user-data
locals {
  user_data_b64 = base64encode(local.user_data)
}

# ----------------------------
# Launch Template
# ----------------------------
resource "aws_launch_template" "api" {
  name_prefix   = "${local.prefix}-api-"
  image_id      = data.aws_ami.al2023.id
  instance_type = var.instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.profile.name
  }

  vpc_security_group_ids = [var.app_sg_id]

  user_data = local.user_data_b64

  # Helpful: ensure replacement happens safely during updates
  update_default_version = true

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name = "${local.prefix}-api"
    })
  }

  tags = var.tags
}

# ----------------------------
# Auto Scaling Group
# ----------------------------
resource "aws_autoscaling_group" "api" {
  name                      = "${local.prefix}-api-asg"
  vpc_zone_identifier       = var.private_subnet_ids
  desired_capacity          = var.desired_capacity
  min_size                  = var.min_size
  max_size                  = var.max_size
  health_check_type         = "ELB"  # use ALB health checks
  health_check_grace_period = 120

  target_group_arns = var.target_group_arns

  launch_template {
    id      = aws_launch_template.api.id
    version = "$Latest"
  }

  # Rolling update behavior
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  tag {
    key                 = "Name"
    value               = "${local.prefix}-api"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}