############################################
# modules/observability/main.tf
# Creates logs, SNS alert topic, alarms, and an optional dashboard
############################################

locals {
  # Consistent resource prefix: geotechlab-prod, geotechlab-dev, etc.
  prefix = "${var.name}-${var.environment}"

  # If app_log_group_name not provided, use a standard default
  app_lg_name = coalesce(var.app_log_group_name, "/aws/${var.name}/${var.environment}/app")
}

############################################
# SNS Topic for alert notifications
############################################

resource "aws_sns_topic" "alerts" {
  name = "${local.prefix}-alerts"
  tags = var.tags
}

# Optional email subscription (only created if alert_email is provided)
resource "aws_sns_topic_subscription" "email" {
  count     = var.alert_email == null ? 0 : 1
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

############################################
# CloudWatch Log Group for application logs
# (Your app/agent must ship logs to this group—this module creates the destination.)
############################################

resource "aws_cloudwatch_log_group" "app" {
  count             = var.create_app_log_group ? 1 : 0
  name              = local.app_lg_name
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

############################################
# CloudWatch Alarms (conditionally created)
#
# NOTE: We guard alarms with:
# - var.enable_alarms
# - presence of required dimensions (alb_arn_suffix, etc.)
############################################

# Helper locals to avoid repeating "enabled && non-null"
locals {
  enable_alb_alarms = var.enable_alarms && var.alb_arn_suffix != null
  enable_tg_alarms  = var.enable_alarms && var.target_group_arn_suffix != null && var.alb_arn_suffix != null
  enable_asg_alarms = var.enable_alarms && var.asg_name != null
  enable_rds_alarms = var.enable_alarms && var.rds_instance_id != null
  enable_ec2_alarms = var.enable_alarms && var.ec2_instance_id != null
}

# ----------------------------
# ALB: Load balancer 5XX errors
# Metric namespace: AWS/ApplicationELB
# Metric: HTTPCode_ELB_5XX_Count
# Dimension: LoadBalancer = <alb_arn_suffix>
# ----------------------------
resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  count = local.enable_alb_alarms ? 1 : 0

  alarm_name          = "${local.prefix}-alb-5xx"
  alarm_description   = "ALB is generating too many 5XX responses (possible infra issue)."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  period              = var.alarm_period_seconds
  statistic           = "Sum"
  threshold           = var.alb_5xx_threshold
  treat_missing_data  = "notBreaching"

  namespace   = "AWS/ApplicationELB"
  metric_name = "HTTPCode_ELB_5XX_Count"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
  tags          = var.tags
}

# ----------------------------
# Target Group: Target 5XX errors
# Metric: HTTPCode_Target_5XX_Count
# Dimensions: LoadBalancer + TargetGroup
# ----------------------------
resource "aws_cloudwatch_metric_alarm" "tg_5xx" {
  count = local.enable_tg_alarms ? 1 : 0

  alarm_name          = "${local.prefix}-tg-5xx"
  alarm_description   = "Targets are returning too many 5XX (application errors)."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  period              = var.alarm_period_seconds
  statistic           = "Sum"
  threshold           = var.tg_5xx_threshold
  treat_missing_data  = "notBreaching"

  namespace   = "AWS/ApplicationELB"
  metric_name = "HTTPCode_Target_5XX_Count"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
    TargetGroup  = var.target_group_arn_suffix
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
  tags          = var.tags
}

# ----------------------------
# Target Group: Unhealthy hosts
# Metric: UnHealthyHostCount
# ----------------------------
resource "aws_cloudwatch_metric_alarm" "unhealthy_hosts" {
  count = local.enable_tg_alarms ? 1 : 0

  alarm_name          = "${local.prefix}-unhealthy-hosts"
  alarm_description   = "One or more targets are unhealthy behind the ALB."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  period              = var.alarm_period_seconds
  statistic           = "Average"
  threshold           = var.unhealthy_hosts_threshold
  treat_missing_data  = "notBreaching"

  namespace   = "AWS/ApplicationELB"
  metric_name = "UnHealthyHostCount"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
    TargetGroup  = var.target_group_arn_suffix
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
  tags          = var.tags
}

# ----------------------------
# ASG: High CPU (EC2 fleet average)
# Metric namespace: AWS/EC2
# Metric: CPUUtilization
# Dimension: AutoScalingGroupName
#
# This gives you a simple "fleet health" signal.
# ----------------------------
resource "aws_cloudwatch_metric_alarm" "asg_cpu_high" {
  count = local.enable_asg_alarms ? 1 : 0

  alarm_name          = "${local.prefix}-asg-cpu-high"
  alarm_description   = "ASG average CPU is high (may need scaling or app optimization)."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  period              = var.alarm_period_seconds
  statistic           = "Average"
  threshold           = var.ec2_cpu_high_threshold
  treat_missing_data  = "notBreaching"

  namespace   = "AWS/EC2"
  metric_name = "CPUUtilization"

  dimensions = {
    AutoScalingGroupName = var.asg_name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
  tags          = var.tags
}

# ----------------------------
# EC2 (single instance): High CPU
# Namespace: AWS/EC2
# Metric: CPUUtilization
# Dimension: InstanceId
#
# This is used for DEV when you deploy a single EC2 instance
# instead of an Auto Scaling Group.
# ----------------------------
resource "aws_cloudwatch_metric_alarm" "ec2_cpu_high" {
  count = local.enable_ec2_alarms ? 1 : 0

  alarm_name          = "${local.prefix}-ec2-cpu-high"
  alarm_description   = "EC2 CPU is high (single-instance dev alarm)."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  period              = var.alarm_period_seconds
  statistic           = "Average"
  threshold           = var.ec2_cpu_high_threshold
  treat_missing_data  = "notBreaching"

  namespace   = "AWS/EC2"
  metric_name = "CPUUtilization"

  dimensions = {
    InstanceId = var.ec2_instance_id
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
  tags          = var.tags
}

# ----------------------------
# RDS: High CPU
# Namespace: AWS/RDS
# Metric: CPUUtilization
# Dimension: DBInstanceIdentifier
# ----------------------------
resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  count = local.enable_rds_alarms ? 1 : 0

  alarm_name          = "${local.prefix}-rds-cpu-high"
  alarm_description   = "RDS CPU is high (potential query load or missing indexes)."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  period              = var.alarm_period_seconds
  statistic           = "Average"
  threshold           = var.rds_cpu_high_threshold
  treat_missing_data  = "notBreaching"

  namespace   = "AWS/RDS"
  metric_name = "CPUUtilization"

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
  tags          = var.tags
}

# ----------------------------
# RDS: Low Free Storage
# Metric: FreeStorageSpace (bytes)
# ----------------------------
resource "aws_cloudwatch_metric_alarm" "rds_free_storage_low" {
  count = local.enable_rds_alarms ? 1 : 0

  alarm_name          = "${local.prefix}-rds-free-storage-low"
  alarm_description   = "RDS FreeStorageSpace is low (risk of outages)."
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  period              = var.alarm_period_seconds
  statistic           = "Average"
  threshold           = var.rds_free_storage_bytes_low_threshold
  treat_missing_data  = "notBreaching"

  namespace   = "AWS/RDS"
  metric_name = "FreeStorageSpace"

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
  tags          = var.tags
}

############################################
# Optional CloudWatch Dashboard
#
# This creates a quick “single pane of glass” view.
# It’s safe to keep in prod; in dev you can disable it.
############################################

resource "aws_cloudwatch_dashboard" "main" {
  count          = var.create_dashboard ? 1 : 0
  dashboard_name = "${local.prefix}-dashboard"

  dashboard_body = jsonencode({
    widgets = compact([
      # ALB 5XX widget (only if alb_arn_suffix present)
      var.alb_arn_suffix == null ? null : {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          title  = "ALB 5XX"
          region = null
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_ELB_5XX_Count", "LoadBalancer", var.alb_arn_suffix]
          ]
          stat   = "Sum"
          period = var.alarm_period_seconds
        }
      },

      # Target 5XX widget (only if tg + alb suffix present)
      (var.target_group_arn_suffix == null || var.alb_arn_suffix == null) ? null : {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          title  = "Target 5XX"
          region = null
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", var.alb_arn_suffix, "TargetGroup", var.target_group_arn_suffix]
          ]
          stat   = "Sum"
          period = var.alarm_period_seconds
        }
      },

      # ASG CPU widget (only if asg_name present)
      var.asg_name == null ? null : {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          title  = "ASG Avg CPU"
          region = null
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", var.asg_name]
          ]
          stat   = "Average"
          period = var.alarm_period_seconds
        }
      },

      # RDS widgets (only if rds_instance_id present)
      var.rds_instance_id == null ? null : {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          title  = "RDS CPU"
          region = null
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", var.rds_instance_id]
          ]
          stat   = "Average"
          period = var.alarm_period_seconds
        }
      }
    ])
  })
}

############################################
# modules/observability/main.tf
# System log group (optional)
############################################

resource "aws_cloudwatch_log_group" "system" {
  count             = var.system_log_group_name == null ? 0 : 1
  name              = var.system_log_group_name
  retention_in_days = var.log_retention_days
  tags              = var.tags
}