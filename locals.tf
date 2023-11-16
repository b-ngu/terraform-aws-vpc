################################################################################
# Locals
################################################################################
locals {
  max_subnet_length = max(
    length(var.private_subnets),
    length(var.elasticache_subnets),
    length(var.database_subnets),
  )
  nat_gateway_count = var.single_nat_gateway ? 1 : var.one_nat_gateway_per_az ? length(var.azs) : local.max_subnet_length

  vpc_id = try(aws_vpc.main.id, "")

  contact     = var.contact
  environment = var.environment
  team        = var.team
  purpose     = var.purpose

  resource_prefix                 = "${local.team}-${local.environment}"
  global_flow_log_destination_arn = "arn:aws:s3:::global-flow-logs-us-west-2"
}