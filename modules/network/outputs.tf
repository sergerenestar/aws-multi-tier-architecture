# Outputs for the network module
output "vpc_id"              { value = aws_vpc.this.id }
output "public_subnet_ids"   { value = [for s in aws_subnet.public : s.id] }
output "private_subnet_ids"  { value = [for s in aws_subnet.private : s.id] }
output "app_sg_id"           { value = aws_security_group.app_sg.id }
output "db_sg_id"            { value = aws_security_group.db_sg.id }
