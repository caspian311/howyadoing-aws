######################################################
# Variables
######################################################

variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "region" {
  default = "us-east-1"
}

variable "network_address_space" {
  default = "10.1.0.0/16"
}
variable "subnet1_address_space" {
  default = "10.1.0.0/24"
}
variable "subnet2_address_space" {
  default = "10.1.1.0/24"
}

variable "app_tag" {
    default = "howyadoing"
}

######################################################
# Providers
######################################################

provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = var.region
}

######################################################
# Data
######################################################

data "aws_availability_zones" "available" {}

######################################################
# Resources
######################################################

# Networking

resource "aws_vpc" "vpc" {
  cidr_block = var.network_address_space

  tags = { Name = "${var.app_tag}-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = { Name = "${var.app_tag}-igw" }

}

resource "aws_subnet" "subnet1" {
  cidr_block              = var.subnet1_address_space
  vpc_id                  = aws_vpc.vpc.id
  map_public_ip_on_launch = "true"
  availability_zone       = data.aws_availability_zones.available.names[0]

  tags = { Name = "${var.app_tag}-subnet1" }

}

resource "aws_subnet" "subnet2" {
  cidr_block              = var.subnet2_address_space
  vpc_id                  = aws_vpc.vpc.id
  map_public_ip_on_launch = "true"
  availability_zone       = data.aws_availability_zones.available.names[1]

  tags = { Name = "${var.app_tag}-subnet2" }

}

# ROUTING #
resource "aws_route_table" "rtb" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = { Name = "${var.app_tag}-rtb" }

}

resource "aws_route_table_association" "rta-subnet1" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.rtb.id
}

resource "aws_route_table_association" "rta-subnet2" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.rtb.id
}

# Security Groups

resource "aws_security_group" "lb-sg" {
  name   = "${var.app_tag}_lb_sg"
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.app_tag}-lb" }
}

resource "aws_security_group" "ec2-sg" {
  name   = "${var.app_tag}_ec2_sg"
  vpc_id = aws_vpc.vpc.id

  # maybe restrict to network space and create a jump box later
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.network_address_space]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.app_tag}-ec2" }
}
