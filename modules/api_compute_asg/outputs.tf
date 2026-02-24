############################################
# modules/api_compute_asg/outputs.tf
############################################

output "asg_name" {
  description = "Auto Scaling Group name (used by observability alarms and dashboards)"
  value       = aws_autoscaling_group.api.name
}

output "launch_template_id" {
  description = "Launch template ID"
  value       = aws_launch_template.api.id
}

output "iam_role_name" {
  description = "IAM role name for ASG instances"
  value       = aws_iam_role.ec2_role.name
}