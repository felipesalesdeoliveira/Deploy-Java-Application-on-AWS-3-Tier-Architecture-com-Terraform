data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ssm_parameter" "ami" {
  name = var.ami_ssm_parameter
}

locals {
  azs  = slice(data.aws_availability_zones.available.names, 0, 2)
  name = "${var.project_name}-${var.environment}"
  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

module "app_vpc" {
  source = "../../modules/vpc"

  name                 = "${local.name}-app"
  cidr_block           = var.app_vpc_cidr
  azs                  = local.azs
  public_subnet_cidrs  = var.app_public_subnet_cidrs
  private_subnet_cidrs = var.app_private_subnet_cidrs
  single_nat_gateway   = var.single_nat_gateway
  enable_flow_logs     = true
  tags                 = local.tags
}

module "data_vpc" {
  source = "../../modules/vpc"

  name                 = "${local.name}-data"
  cidr_block           = var.data_vpc_cidr
  azs                  = local.azs
  public_subnet_cidrs  = []
  private_subnet_cidrs = var.data_private_subnet_cidrs
  single_nat_gateway   = false
  enable_flow_logs     = true
  tags                 = local.tags
}

resource "aws_ec2_transit_gateway" "this" {
  description = "${local.name} transit gateway"

  tags = merge(local.tags, {
    Name = "${local.name}-tgw"
  })
}

resource "aws_ec2_transit_gateway_vpc_attachment" "app" {
  subnet_ids         = module.app_vpc.private_subnet_ids
  transit_gateway_id = aws_ec2_transit_gateway.this.id
  vpc_id             = module.app_vpc.vpc_id

  tags = merge(local.tags, {
    Name = "${local.name}-tgw-attach-app"
  })
}

resource "aws_ec2_transit_gateway_vpc_attachment" "data" {
  subnet_ids         = module.data_vpc.private_subnet_ids
  transit_gateway_id = aws_ec2_transit_gateway.this.id
  vpc_id             = module.data_vpc.vpc_id

  tags = merge(local.tags, {
    Name = "${local.name}-tgw-attach-data"
  })
}

resource "aws_route" "app_to_data" {
  count = length(module.app_vpc.private_route_table_ids)

  route_table_id         = module.app_vpc.private_route_table_ids[count.index]
  destination_cidr_block = module.data_vpc.vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.this.id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.app, aws_ec2_transit_gateway_vpc_attachment.data]
}

resource "aws_route" "data_to_app" {
  count = length(module.data_vpc.private_route_table_ids)

  route_table_id         = module.data_vpc.private_route_table_ids[count.index]
  destination_cidr_block = module.app_vpc.vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.this.id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.app, aws_ec2_transit_gateway_vpc_attachment.data]
}

module "rds" {
  source = "../../modules/rds"

  name                       = local.name
  db_name                    = var.db_name
  db_username                = var.db_username
  db_password                = var.db_password
  vpc_id                     = module.data_vpc.vpc_id
  subnet_ids                 = module.data_vpc.private_subnet_ids
  allowed_cidr_blocks        = [module.app_vpc.vpc_cidr]
  allowed_security_group_ids = []
  instance_class             = var.db_instance_class
  allocated_storage          = var.db_allocated_storage
  multi_az                   = var.db_multi_az
  replica_count              = var.db_replica_count
  backup_retention_period    = var.db_backup_retention
  deletion_protection        = var.db_deletion_protection
  tags                       = local.tags

  depends_on = [aws_route.app_to_data, aws_route.data_to_app]
}

module "app_tier" {
  source = "../../modules/app-tier"

  name                   = local.name
  vpc_id                 = module.app_vpc.vpc_id
  public_subnet_ids      = module.app_vpc.public_subnet_ids
  private_subnet_ids     = module.app_vpc.private_subnet_ids
  ami_id                 = data.aws_ssm_parameter.ami.value
  instance_type_frontend = var.frontend_instance_type
  instance_type_backend  = var.backend_instance_type
  frontend_desired       = var.frontend_desired
  frontend_min           = var.frontend_min
  frontend_max           = var.frontend_max
  backend_desired        = var.backend_desired
  backend_min            = var.backend_min
  backend_max            = var.backend_max
  ingress_http_cidrs     = var.ingress_http_cidrs
  frontend_user_data = templatefile("../../scripts/userdata_frontend.sh.tpl", {
    backend_nlb_name = "${local.name}-back-nlb"
    aws_region       = var.aws_region
  })
  backend_user_data = templatefile("../../scripts/userdata_backend.sh.tpl", {
    db_endpoint       = module.rds.endpoint
    db_port           = module.rds.port
    db_name           = var.db_name
    db_username       = var.db_username
    db_password       = var.db_password
    java_artifact_url = var.java_artifact_url
  })
  tags = local.tags
}

module "bastion" {
  source = "../../modules/bastion"
  count  = var.create_bastion ? 1 : 0

  name              = local.name
  vpc_id            = module.app_vpc.vpc_id
  subnet_id         = module.app_vpc.public_subnet_ids[0]
  ami_id            = data.aws_ssm_parameter.ami.value
  instance_type     = var.bastion_instance_type
  allowed_ssh_cidrs = var.bastion_allowed_ssh_cidrs
  key_name          = var.bastion_key_name
  tags              = local.tags
}

resource "aws_route53_record" "frontend" {
  count = 0

  zone_id = "Z0000000000000"
  name    = "app.${var.environment}.example.com"
  type    = "CNAME"
  ttl     = 300
  records = [module.app_tier.frontend_nlb_dns]
}
