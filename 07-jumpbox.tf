resource "aws_instance" "jump-box" {
  ami                    = data.aws_ami.aws-linux.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.subnet1.id
  vpc_security_group_ids = [aws_security_group.ec2-jump-box-sg.id]
  key_name               = aws_key_pair.key_pair.key_name

  tags = { Name = "${var.app_tag}-jump-box" }
}