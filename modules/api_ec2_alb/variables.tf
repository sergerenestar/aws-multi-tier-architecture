variable "name" { type = string }

variable "vpc_id"             { type = string }
variable "public_subnet_ids"  { type = list(string) }
variable "private_subnet_ids" { type = list(string) }

variable "app_sg_id" { type = string }
variable "app_port"  { type = number }

variable "db_host"     { type = string }
variable "db_port"     { type = number }
variable "db_name"     { type = string }
variable "db_username" { type = string }
variable "db_password" {
  type = string
  sensitive = true
  }

variable "app_s3_bucket" { type = string }
variable "app_s3_key"    { type = string }

variable "cors_allowed_origins" {
  type = string
default = "*"
}
