############################################
# modules/api_asg_alb/outputs.tf
# Standardize outputs so prod/dev can share the same observability wiring
############################################

output "alb_dns_name" {
  value = module.common.alb_dns_name
}

output "alb_arn_suffix" {
  value = module.common.alb_arn_suffix
}

output "target_group_arn_suffix" {
  value = module.common.target_group_arn_suffix
}

output "alb_sg_id" {
  value = module.common.alb_sg_id
}

output "asg_name" {
  description = "ASG name for group-level alarms"
  value       = module.compute.asg_name
}