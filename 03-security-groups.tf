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