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
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.api-cert.arn
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api-tg.arn
  }
}

resource "aws_lb_listener" "non-secure" {
  load_balancer_arn = aws_lb.api-lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
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
docker run --rm \
    -e NODE_ENV=production \
    -e DATABASE_HOST=${aws_db_instance.database.address} \
    -e DATABASE_NAME=${aws_db_instance.database.name} \
    -e DATABASE_USER=${aws_db_instance.database.username} \
    -e DATABASE_PASSWORD=${aws_db_instance.database.password} \
    -v /root/howyadoing-api:/app \
    node /app/migrate.sh
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