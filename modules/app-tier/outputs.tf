output "frontend_nlb_dns" {
  value = aws_lb.frontend.dns_name
}

output "backend_nlb_dns" {
  value = aws_lb.backend.dns_name
}

output "frontend_security_group_id" {
  value = aws_security_group.frontend.id
}

output "backend_security_group_id" {
  value = aws_security_group.backend.id
}
