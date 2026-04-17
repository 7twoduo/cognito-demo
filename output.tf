
output "alb_dns_name" {
  value = aws_lb.app.dns_name
}

output "db_endpoint" {
  value = aws_db_instance.postgres.address
}