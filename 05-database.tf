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