output "endpoint" {
  value = aws_db_instance.primary.address
}

output "port" {
  value = aws_db_instance.primary.port
}

output "security_group_id" {
  value = aws_security_group.rds.id
}
