output "frontend_nlb_dns" {
  value = module.app_tier.frontend_nlb_dns
}

output "backend_nlb_dns" {
  value = module.app_tier.backend_nlb_dns
}

output "rds_endpoint" {
  value = module.rds.endpoint
}

output "rds_port" {
  value = module.rds.port
}

output "bastion_public_ip" {
  value = var.create_bastion ? module.bastion[0].public_ip : null
}
