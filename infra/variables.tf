variable "aws_region" {
  type    = string
  default = "eu-west-2"
}

variable "project_name" {
  type    = string
  default = "three-tier"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "azs" {
  type    = list(string)
  default = ["eu-west-2a", "eu-west-2b"]
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.0.0/24", "10.0.1.0/24"]
}

variable "web_private_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "app_private_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.20.0/24", "10.0.21.0/24"]
}

variable "db_private_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.30.0/24", "10.0.31.0/24"]
}

variable "web_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "app_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "web_desired_capacity" {
  type    = number
  default = 2
}

variable "app_desired_capacity" {
  type    = number
  default = 2
}

# Route53
variable "route53_zone_id" {
  type        = string
  description = "Route53 Hosted Zone ID for samproject.com"
}

variable "dns_name" {
  type        = string
  description = "Record to create, e.g. app.samproject.com"
}

# Aurora MySQL
variable "db_name" {
  type    = string
  default = "appdb"
}

variable "db_master_username" {
  type    = string
  default = "admin"
}

variable "db_master_password" {
  type        = string
  description = "Set in terraform.tfvars (DO NOT COMMIT)."
  sensitive   = true
}

variable "aurora_engine_version" {
  type    = string
  default = "8.0.mysql_aurora.3.06.0"
}

variable "aurora_instance_class" {
  type    = string
  default = "db.t3.medium"
}
