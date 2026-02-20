# Network module for creating VPC, subnets, and security groups
# data source to get availability zones
data "aws_availability_zones" "az" {}

# Create VPC with CIDR block and enable DNS support and hostnames
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "${var.name}-vpc" }
}

#  create igw and attach to vpc
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
}

# Create public subnet in each availability zone
resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index) # create subnets with /24 mask
  availability_zone       = data.aws_availability_zones.az.names[count.index] # assign each subnet to a different AZ
  map_public_ip_on_launch = true
  tags = { Name = "${var.name}-public-${count.index}" }
}

# Create private subnet in each availability zone

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10) # create private subnets with /24 mask in a different range the +10 to avoid overlap with public subnets
  availability_zone = data.aws_availability_zones.az.names[count.index]
  tags = { Name = "${var.name}-private-${count.index}" }
}
# create route table for public subnets and associate with igw
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route { 
    cidr_block = "0.0.0.0/0" 
    gateway_id = aws_internet_gateway.igw.id 
    }
}

# associate public subnets with route table to allow internet access
resource "aws_route_table_association" "public_assoc" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# NAT (best practice)

# Create Elastic IP for NAT Gateway
resource "aws_eip" "nat" { domain = "vpc" }

# Create NAT Gateway in the first public subnet,
#his will allow instances in private subnets to access the internet
#for updates and patches without exposing them directly to the internet
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id
  depends_on    = [aws_internet_gateway.igw]
}

# Create route table for private subnets and route internet traffic through NAT Gateway
# this ensures that instances in private subnets can access the internet for updates and patches without being directly exposed to the internet, enhancing security while maintaining necessary connectivity.
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
    }
}

# Associate private subnets with the private route table to ensure they use the NAT Gateway for internet access
resource "aws_route_table_association" "private_assoc" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
#---------------------------
# Shared SGs
#--------------------------
resource "aws_security_group" "app_sg" {
  name   = "${var.name}-app-sg"
  vpc_id = aws_vpc.this.id

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "db_sg" {
  name   = "${var.name}-db-sg"
  vpc_id = aws_vpc.this.id

  ingress {
    from_port       = var.db_port
    to_port         = var.db_port
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    }
}

