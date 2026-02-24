############################################
# modules/api_common_alb/outputs.tf
############################################

output "alb_dns_name" {
  description = "Public DNS name of the ALB"
  value       = aws_lb.alb.dns_name
}

output "alb_arn_suffix" {
  description = "ALB ARN suffix (needed for CloudWatch ALB metrics)"
  value       = aws_lb.alb.arn_suffix
}

output "alb_sg_id" {
  description = "Security group ID of the ALB"
  value       = aws_security_group.alb_sg.id
}

output "target_group_arn" {
  description = "Target Group ARN"
  value       = aws_lb_target_group.tg.arn
}

output "target_group_arn_suffix" {
  description = "Target Group ARN suffix (needed for CloudWatch TG metrics)"
  value       = aws_lb_target_group.tg.arn_suffix
}