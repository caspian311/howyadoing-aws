######################################################
# Variables
######################################################

variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "region" {
  default = "us-east-2"
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

variable "site_bucket_name" {
    default = "howyadoing.coffeemonkey.net"
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

data "aws_ami" "aws-linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-hvm*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "random_password" "password" {
  length = 16
  special = true
  override_special = "_%@ "
}

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

resource "aws_db_subnet_group" "default" {
  name       = "${var.app_tag}_subnet_group"
  subnet_ids = ["${aws_subnet.subnet1.id}", "${aws_subnet.subnet2.id}"]
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

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.network_address_space]
  }

  ingress {
    from_port   = 5555
    to_port     = 5555
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

resource "aws_security_group" "ec2-jump-box-sg" {
  name   = "${var.app_tag}_ec2_jump_box_sg"
  vpc_id = aws_vpc.vpc.id

  # maybe restrict to network space and create a jump box later
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.app_tag}-ec2-jumpbox" }
}

resource "aws_security_group" "db-sg" {
  name   = "${var.app_tag}_db_sg"
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.network_address_space]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.app_tag}-db-sg" }
}

# Load Balancer

resource "aws_lb" "api-lb" {
  name = "${var.app_tag}-api-lb"
  internal = false
  load_balancer_type = "application"

  subnets         = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
  security_groups = [aws_security_group.lb-sg.id]

  tags = { Name = "${var.app_tag}-lb" }
}

# Target Group

resource "aws_lb_target_group" "api-tg" {
  name     = "${var.app_tag}-api-tg"
  port     = 5555
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id
}

# Listener

resource "aws_lb_listener" "api-listener" {
  load_balancer_arn = aws_lb.api-lb.arn
  port              = "80"
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api-tg.arn
  }
}

# Key Pair

resource "tls_private_key" "private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "key_pair" {
  key_name   = "${var.app_tag}-key"
  public_key = tls_private_key.private_key.public_key_openssh
}

resource "local_file" "public_key_openssh" {
    content     = tls_private_key.private_key.public_key_openssh
    filename    = "${var.app_tag}-key.pub"
}

resource "local_file" "private_key_pem" {
    content     = tls_private_key.private_key.private_key_pem
    filename    = "${var.app_tag}-key.pem"
}

# Launch Configuration

resource "aws_launch_configuration" "api-launch-config" {
  image_id        = data.aws_ami.aws-linux.id
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.ec2-sg.id]
  key_name        = aws_key_pair.key_pair.key_name
  name_prefix     = "${var.app_tag}-api-"
  user_data       = <<EOF
#!/bin/bash

# for instance ID ami-0323c3dd2da7fb37d

yum install -y git docker
service docker start
docker pull node

git clone https://github.com/caspian311/howyadoing-api.git /root/howyadoing-api
git checkout release
echo "docker run ... --rm -v /root/howyadoing-api:/app -p 5555:5555 node /app/startup.sh"
docker run --rm \
    -e NODE_ENV=production \
    -e DATABASE_HOST=${aws_db_instance.database.address} \
    -e DATABASE_NAME=${aws_db_instance.database.name} \
    -e DATABASE_USER=${aws_db_instance.database.username} \
    -e DATABASE_PASSWORD=${aws_db_instance.database.password} \
    -v /root/howyadoing-api:/app \
    -p 5555:5555 \
    node /app/startup.sh
EOF
}

# Autoscaling Group

resource "aws_autoscaling_policy" "api-asg-policy" {
  name                   = "${var.app_tag}-asg-policy"
  adjustment_type        = "ChangeInCapacity"
  autoscaling_group_name = aws_autoscaling_group.api-asg.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value         = 40
  }
}

resource "aws_autoscaling_group" "api-asg" {
  name                      = "${var.app_tag}-asg"
  max_size                  = 2
  min_size                  = 1
  force_delete              = true
  launch_configuration      = aws_launch_configuration.api-launch-config.name
  vpc_zone_identifier       = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
  target_group_arns         = [aws_lb_target_group.api-tg.arn]
}

# Database

resource "aws_db_instance" "database" {
  identifier           = "${var.app_tag}-db"
  allocated_storage    = 5
  engine               = "mysql"
  instance_class       = "db.t2.micro"
  name                 = var.app_tag
  username             = "user1"
  password             = random_password.password.result
  db_subnet_group_name = aws_db_subnet_group.default.name
  vpc_security_group_ids = [aws_security_group.db-sg.id]
  skip_final_snapshot = true
}

# S3 bucket

resource "aws_s3_bucket" "website" {
  bucket = var.site_bucket_name
  acl    = "public-read"
  force_destroy = true

  website {
    index_document = "index.html"
    error_document = "error.html"
  }

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "AddPerm",
    "Effect": "Allow",
    "Principal": "*",
    "Action": "s3:GetObject",
    "Resource": "arn:aws:s3:::howyadoing.coffeemonkey.net/*"
  }]
}
EOF
}

# Jump Box

resource "aws_instance" "jump-box" {
  ami                    = data.aws_ami.aws-linux.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.subnet1.id
  vpc_security_group_ids = [aws_security_group.ec2-jump-box-sg.id]
  key_name               = aws_key_pair.key_pair.key_name

  tags = { Name = "${var.app_tag}-jump-box" }
}

######################################################
# Outputs
######################################################

output "api_lb_public_dns" {
  value = aws_lb.api-lb.dns_name
}

output "db_hostname" {
  value = aws_db_instance.database.address
}

output "db_username" {
  value = aws_db_instance.database.username
}

output "db_password" {
  value = aws_db_instance.database.password
}