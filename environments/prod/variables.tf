variable "aws_region" {
  type = string
}

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "app_vpc_cidr" {
  type = string
}

variable "data_vpc_cidr" {
  type = string
}

variable "app_public_subnet_cidrs" {
  type = list(string)
}

variable "app_private_subnet_cidrs" {
  type = list(string)
}

variable "data_private_subnet_cidrs" {
  type = list(string)
}

variable "single_nat_gateway" {
  type    = bool
  default = true
}

variable "ami_ssm_parameter" {
  type    = string
  default = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

variable "frontend_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "backend_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "frontend_desired" {
  type    = number
  default = 2
}

variable "frontend_min" {
  type    = number
  default = 2
}

variable "frontend_max" {
  type    = number
  default = 4
}

variable "backend_desired" {
  type    = number
  default = 2
}

variable "backend_min" {
  type    = number
  default = 2
}

variable "backend_max" {
  type    = number
  default = 4
}

variable "ingress_http_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "db_name" {
  type = string
}

variable "db_username" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.medium"
}

variable "db_allocated_storage" {
  type    = number
  default = 20
}

variable "db_multi_az" {
  type    = bool
  default = true
}

variable "db_replica_count" {
  type    = number
  default = 0
}

variable "db_backup_retention" {
  type    = number
  default = 7
}

variable "db_deletion_protection" {
  type    = bool
  default = false
}

variable "create_bastion" {
  type    = bool
  default = false
}

variable "bastion_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "bastion_allowed_ssh_cidrs" {
  type    = list(string)
  default = []
}

variable "bastion_key_name" {
  type    = string
  default = null
}

variable "java_artifact_url" {
  description = "Optional URL for WAR/JAR artifact"
  type        = string
  default     = ""
}
