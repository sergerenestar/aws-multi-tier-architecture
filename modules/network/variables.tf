# Variables for the network module
variable "name"     { type = string }
variable "vpc_cidr" { type = string }
variable "db_port"  {
  type = number
  default = 3306
  }