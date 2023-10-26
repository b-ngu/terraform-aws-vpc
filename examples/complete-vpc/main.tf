provider "aws" {
  region = var.region
}

data "aws_availability_zones" "available" {
  filter {
    name   = "region-name"
    values = [var.region]
  }
}

locals {
  name = basename(path.cwd)
  # var.cluster_name used in Terratest
  cluster_name = coalesce(var.cluster_name, local.name)
  vpc_cidr     = "10.0.0.0/16"

  # grab the first to AZs from the data object
  azs = slice(data.aws_availability_zones.available.names, 0, 2)

  resource_prefix = "${var.team}-${var.environment}-${var.purpose}"

  tags = {
    "contact"     = var.contact
    "environment" = var.environment
    "team"        = var.team
    "purpose"     = var.purpose
  }
}
################################################################################
# VPC Module
################################################################################

module "vpc" {
  source = "../../"

  name        = local.name
  contact     = var.contact
  environment = var.environment
  team        = var.team
  purpose     = var.purpose

  cidr = "10.0.0.0/16"

  azs             = local.azs
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k)]
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 10)]

  enable_dns_hostnames = true
  enable_dns_support   = true

  manage_default_network_acl = true
  default_network_acl_tags   = { Name = "${local.resource_prefix}-default" }

  manage_default_route_table = true
  default_route_table_tags   = { Name = "${local.resource_prefix}-default" }

  manage_default_security_group = true
  default_security_group_tags   = { Name = "${local.resource_prefix}-default" }


  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = 1
  }

  tags = local.tags
}

resource "aws_security_group" "vpc_tls" {
  name_prefix = "${local.name}-vpc-tls-sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  tags = merge(
    { "Name" : "${local.name}-vpc-tls-sg" },
    local.tags
  )
}