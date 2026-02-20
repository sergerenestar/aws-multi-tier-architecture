resource "aws_db_subnet_group" "this"{
  name        = "${var.name}-db-subnets"
  subnet_ids  = var.subnet_ids
}

resource "aws_db_instance" "mysql"{
  #db instance type
  identifier          = "${var.name}-mysql"
  engine              = "mysql"
  engine_version      = "8.0"
  instance_class      = var.instance_class
  allocated_storage = 20

#db config
  db_name = var.db_name
  username = var.db_username
  password = var.db_password
  port = 3306

#db network confib
  db_subnet_group_name  = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.db_sg_id]

#db parameters 
  publicly_accessible      = false
  storage_encrypted        = true
  backup_retention_period  = 7
  skip_final_snapshot      = true
  

}

