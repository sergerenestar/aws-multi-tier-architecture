variable "name" { type = string}
variable " vpc_id" {type = string}
variable "public_subnet_ids" {type = list(string)}
variable "private_subnet_ids" {type = list(string)}

# Security group for the ALB
variable "app_sg_id" {type = string}
variable "app_port" { type =  number}

# db host and port for the ALB to connect to the RDS instance
variable "db_host" {type = string}
variable "db_port" {type = number}
variable "db_name" {type = string}
variable "db_username" {type = string}
variable "db_password" {type = string}

# S3 bucket and key for the ALB to fetch the application code
variable "app_s3_bucket" { type = string}
variable "app_s3_key" { type = string}

# CORS allowed origins for the ALB
variable "cors_allowed_origins" {
  type = string
  default = "*"
}

