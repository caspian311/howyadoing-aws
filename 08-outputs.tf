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