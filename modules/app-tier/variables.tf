variable "name" {
  description = "Name prefix for app tier resources"
  type        = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "ami_id" {
  description = "EC2 AMI ID"
  type        = string
}

variable "instance_type_frontend" {
  type    = string
  default = "t3.micro"
}

variable "instance_type_backend" {
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

variable "frontend_user_data" {
  description = "Rendered user data script for frontend nginx instances"
  type        = string
}

variable "backend_user_data" {
  description = "Rendered user data script for backend tomcat instances"
  type        = string
}

variable "ingress_http_cidrs" {
  description = "Allowed source CIDRs for public HTTP"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "tags" {
  type    = map(string)
  default = {}
}
