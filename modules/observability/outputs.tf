############################################
# modules/observability/outputs.tf
############################################

output "alerts_topic_arn" {
  description = "SNS topic ARN used for alarm notifications"
  value       = aws_sns_topic.alerts.arn
}

output "app_log_group_name" {
  description = "CloudWatch Log Group name for application logs (if created)"
  value       = try(aws_cloudwatch_log_group.app[0].name, null)
}

output "dashboard_name" {
  description = "CloudWatch dashboard name (if created)"
  value       = try(aws_cloudwatch_dashboard.main[0].dashboard_name, null)
}

output "system_log_group_name" {
  description = "CloudWatch Log Group name for system logs (if created)"
  value       = try(aws_cloudwatch_log_group.system[0].name, null)
}