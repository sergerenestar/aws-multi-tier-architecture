############################################
# modules/api_common_alb/main.tf
# Creates:
# - ALB Security Group (public HTTP)
# - ALB (in public subnets)
# - Listener (HTTP)
# - Target Group (instance target type)
# - SG rule: allow ALB -> App on app_port
############################################

locals {
  prefix = "${var.name}-${var.environment}"
}

# ----------------------------
# ALB Security Group
# ----------------------------
resource "aws_security_group" "alb_sg" {
  name        = "${local.prefix}-alb-sg"
  description = "ALB security group: allow inbound HTTP from Internet"
  vpc_id      = var.vpc_id
  tags        = var.tags
}

# Inbound HTTP from anywhere (public ALB)
resource "aws_security_group_rule" "alb_ingress_http" {
  type              = "ingress"
  security_group_id = aws_security_group.alb_sg.id

  from_port   = var.alb_listener_port
  to_port     = var.alb_listener_port
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  description = "Allow public HTTP to ALB"
}

# Egress: allow all (ALB needs to reach targets; restricting is optional)
resource "aws_security_group_rule" "alb_egress_all" {
  type              = "egress"
  security_group_id = aws_security_group.alb_sg.id

  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  description = "Allow ALB outbound traffic"
}

# ----------------------------
# Allow ALB -> App SG on app_port
# (Matches your diagram: App SG allows var.app_port from ALB SG) 
# ----------------------------
resource "aws_security_group_rule" "alb_to_app" {
  type                     = "ingress"
  security_group_id        = var.app_sg_id
  from_port                = var.app_port
  to_port                  = var.app_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb_sg.id

  description = "Allow ALB to reach app targets on app_port"
}

# ----------------------------
# ALB
# ----------------------------
resource "aws_lb" "alb" {
  name               = "${local.prefix}-alb"
  load_balancer_type = "application"
  internal           = false

  security_groups = [aws_security_group.alb_sg.id]
  subnets         = var.public_subnet_ids

  tags = var.tags
}

# ----------------------------
# Target Group (instance targets; EC2 or ASG instances)
# ----------------------------
resource "aws_lb_target_group" "tg" {
  name        = "${local.prefix}-tg"
  port        = var.app_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    path                = var.health_check_path
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = var.tags
}

# ----------------------------
# Listener: HTTP -> forward to Target Group
# ----------------------------
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = var.alb_listener_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }

  tags = var.tags
}