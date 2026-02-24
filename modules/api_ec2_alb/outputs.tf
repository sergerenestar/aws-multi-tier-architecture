############################################
# modules/api_ec2_alb/outputs.tf
############################################

output "alb_dns_name" { value = module.common.alb_dns_name }
output "alb_arn_suffix" { value = module.common.alb_arn_suffix }
output "target_group_arn_suffix" { value = module.common.target_group_arn_suffix }

output "instance_id" { value = module.compute.instance_id }
output "alb_sg_id"   { value = module.common.alb_sg_id }