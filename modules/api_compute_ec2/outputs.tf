############################################
# modules/api_compute_ec2/outputs.tf
############################################

output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.api.id
}

output "private_ip" {
  description = "EC2 private IP"
  value       = aws_instance.api.private_ip
}

output "iam_role_name" {
  description = "Name of the IAM role attached to EC2"
  value       = aws_iam_role.ec2_role.name
}