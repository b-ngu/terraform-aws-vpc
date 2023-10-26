################################################################################
# Default Network ACLs
################################################################################

resource "aws_default_network_acl" "default_nacl" {
  count = var.manage_default_network_acl ? 1 : 0

  default_network_acl_id = aws_vpc.main.default_network_acl_id

  # subnet_ids is using lifecycle ignore_changes, so it is not necessary to list
  # any explicitly.
  subnet_ids = null

  dynamic "ingress" {
    for_each = var.default_network_acl_ingress
    content {
      action          = ingress.value.action
      cidr_block      = lookup(ingress.value, "cidr_block", null)
      from_port       = ingress.value.from_port
      icmp_code       = lookup(ingress.value, "icmp_code", null)
      icmp_type       = lookup(ingress.value, "icmp_type", null)
      ipv6_cidr_block = lookup(ingress.value, "ipv6_cidr_block", null)
      protocol        = ingress.value.protocol
      rule_no         = ingress.value.rule_no
      to_port         = ingress.value.to_port
    }
  }
  dynamic "egress" {
    for_each = var.default_network_acl_egress
    content {
      action          = egress.value.action
      cidr_block      = lookup(egress.value, "cidr_block", null)
      from_port       = egress.value.from_port
      icmp_code       = lookup(egress.value, "icmp_code", null)
      icmp_type       = lookup(egress.value, "icmp_type", null)
      ipv6_cidr_block = lookup(egress.value, "ipv6_cidr_block", null)
      protocol        = egress.value.protocol
      rule_no         = egress.value.rule_no
      to_port         = egress.value.to_port
    }
  }

  tags = merge(
    { "Name" = coalesce(var.default_network_acl_name, "${local.resource_prefix}-default-nacl") },
    var.tags,
    var.default_network_acl_tags,
  )

  lifecycle {
    ignore_changes = [subnet_ids]
  }
}

################################################################################
# Public Network ACLs
################################################################################

resource "aws_network_acl" "public" {
  count = var.public_dedicated_network_acl && length(var.public_subnets) > 0 ? 1 : 0

  vpc_id     = local.vpc_id
  subnet_ids = aws_subnet.public[*].id

  tags = merge(
    { "Name" = "${local.resource_prefix}-${var.public_subnet_suffix}-nacl" },
    var.tags,
    var.public_acl_tags,
  )
}

resource "aws_network_acl_rule" "public_inbound" {
  count = var.public_dedicated_network_acl && length(var.public_subnets) > 0 ? length(var.public_inbound_acl_rules) : 0

  network_acl_id = aws_network_acl.public[0].id

  egress      = false
  rule_number = var.public_inbound_acl_rules[count.index]["rule_number"]
  rule_action = var.public_inbound_acl_rules[count.index]["rule_action"]
  from_port   = lookup(var.public_inbound_acl_rules[count.index], "from_port", null)
  to_port     = lookup(var.public_inbound_acl_rules[count.index], "to_port", null)
  icmp_code   = lookup(var.public_inbound_acl_rules[count.index], "icmp_code", null)
  icmp_type   = lookup(var.public_inbound_acl_rules[count.index], "icmp_type", null)
  protocol    = var.public_inbound_acl_rules[count.index]["protocol"]
  cidr_block  = lookup(var.public_inbound_acl_rules[count.index], "cidr_block", null)
}

resource "aws_network_acl_rule" "public_outbound" {
  count = var.public_dedicated_network_acl && length(var.public_subnets) > 0 ? length(var.public_outbound_acl_rules) : 0

  network_acl_id = aws_network_acl.public[0].id

  egress      = true
  rule_number = var.public_outbound_acl_rules[count.index]["rule_number"]
  rule_action = var.public_outbound_acl_rules[count.index]["rule_action"]
  from_port   = lookup(var.public_outbound_acl_rules[count.index], "from_port", null)
  to_port     = lookup(var.public_outbound_acl_rules[count.index], "to_port", null)
  icmp_code   = lookup(var.public_outbound_acl_rules[count.index], "icmp_code", null)
  icmp_type   = lookup(var.public_outbound_acl_rules[count.index], "icmp_type", null)
  protocol    = var.public_outbound_acl_rules[count.index]["protocol"]
  cidr_block  = lookup(var.public_outbound_acl_rules[count.index], "cidr_block", null)
}

################################################################################
# Private Network ACLs
################################################################################

resource "aws_network_acl" "private" {
  count = var.private_dedicated_network_acl && length(var.private_subnets) > 0 ? 1 : 0

  vpc_id     = local.vpc_id
  subnet_ids = aws_subnet.private[*].id

  tags = merge(
    { "Name" = "${local.resource_prefix}-${var.private_subnet_suffix}-nacl" },
    var.tags,
    var.private_acl_tags,
  )
}

resource "aws_network_acl_rule" "private_inbound" {
  count = var.private_dedicated_network_acl && length(var.private_subnets) > 0 ? length(var.private_inbound_acl_rules) : 0

  network_acl_id = aws_network_acl.private[0].id

  egress      = false
  rule_number = var.private_inbound_acl_rules[count.index]["rule_number"]
  rule_action = var.private_inbound_acl_rules[count.index]["rule_action"]
  from_port   = lookup(var.private_inbound_acl_rules[count.index], "from_port", null)
  to_port     = lookup(var.private_inbound_acl_rules[count.index], "to_port", null)
  icmp_code   = lookup(var.private_inbound_acl_rules[count.index], "icmp_code", null)
  icmp_type   = lookup(var.private_inbound_acl_rules[count.index], "icmp_type", null)
  protocol    = var.private_inbound_acl_rules[count.index]["protocol"]
  cidr_block  = lookup(var.private_inbound_acl_rules[count.index], "cidr_block", null)
}

resource "aws_network_acl_rule" "private_outbound" {
  count = var.private_dedicated_network_acl && length(var.private_subnets) > 0 ? length(var.private_outbound_acl_rules) : 0

  network_acl_id = aws_network_acl.private[0].id

  egress      = true
  rule_number = var.private_outbound_acl_rules[count.index]["rule_number"]
  rule_action = var.private_outbound_acl_rules[count.index]["rule_action"]
  from_port   = lookup(var.private_outbound_acl_rules[count.index], "from_port", null)
  to_port     = lookup(var.private_outbound_acl_rules[count.index], "to_port", null)
  icmp_code   = lookup(var.private_outbound_acl_rules[count.index], "icmp_code", null)
  icmp_type   = lookup(var.private_outbound_acl_rules[count.index], "icmp_type", null)
  protocol    = var.private_outbound_acl_rules[count.index]["protocol"]
  cidr_block  = lookup(var.private_outbound_acl_rules[count.index], "cidr_block", null)
}

################################################################################
# Intra Network ACLs
################################################################################

resource "aws_network_acl" "intra" {
  count = var.intra_dedicated_network_acl && length(var.intra_subnets) > 0 ? 1 : 0

  vpc_id     = local.vpc_id
  subnet_ids = aws_subnet.intra[*].id

  tags = merge(
    { "Name" = "${local.resource_prefix}-${var.intra_subnet_suffix}-nacl" },
    var.tags,
    var.intra_acl_tags,
  )
}

resource "aws_network_acl_rule" "intra_inbound" {
  count = var.intra_dedicated_network_acl && length(var.intra_subnets) > 0 ? length(var.intra_inbound_acl_rules) : 0

  network_acl_id = aws_network_acl.intra[0].id

  egress      = false
  rule_number = var.intra_inbound_acl_rules[count.index]["rule_number"]
  rule_action = var.intra_inbound_acl_rules[count.index]["rule_action"]
  from_port   = lookup(var.intra_inbound_acl_rules[count.index], "from_port", null)
  to_port     = lookup(var.intra_inbound_acl_rules[count.index], "to_port", null)
  icmp_code   = lookup(var.intra_inbound_acl_rules[count.index], "icmp_code", null)
  icmp_type   = lookup(var.intra_inbound_acl_rules[count.index], "icmp_type", null)
  protocol    = var.intra_inbound_acl_rules[count.index]["protocol"]
  cidr_block  = lookup(var.intra_inbound_acl_rules[count.index], "cidr_block", null)
}

resource "aws_network_acl_rule" "intra_outbound" {
  count = var.intra_dedicated_network_acl && length(var.intra_subnets) > 0 ? length(var.intra_outbound_acl_rules) : 0

  network_acl_id = aws_network_acl.intra[0].id

  egress      = true
  rule_number = var.intra_outbound_acl_rules[count.index]["rule_number"]
  rule_action = var.intra_outbound_acl_rules[count.index]["rule_action"]
  from_port   = lookup(var.intra_outbound_acl_rules[count.index], "from_port", null)
  to_port     = lookup(var.intra_outbound_acl_rules[count.index], "to_port", null)
  icmp_code   = lookup(var.intra_outbound_acl_rules[count.index], "icmp_code", null)
  icmp_type   = lookup(var.intra_outbound_acl_rules[count.index], "icmp_type", null)
  protocol    = var.intra_outbound_acl_rules[count.index]["protocol"]
  cidr_block  = lookup(var.intra_outbound_acl_rules[count.index], "cidr_block", null)
}

################################################################################
# Database Network ACLs
################################################################################

resource "aws_network_acl" "database" {
  count = var.database_dedicated_network_acl && length(var.database_subnets) > 0 ? 1 : 0

  vpc_id     = local.vpc_id
  subnet_ids = aws_subnet.database[*].id

  tags = merge(
    { "Name" = "${local.resource_prefix}-${var.database_subnet_suffix}-nacl" },
    var.tags,
    var.database_acl_tags,
  )
}

resource "aws_network_acl_rule" "database_inbound" {
  count = var.database_dedicated_network_acl && length(var.database_subnets) > 0 ? length(var.database_inbound_acl_rules) : 0

  network_acl_id = aws_network_acl.database[0].id

  egress      = false
  rule_number = var.database_inbound_acl_rules[count.index]["rule_number"]
  rule_action = var.database_inbound_acl_rules[count.index]["rule_action"]
  from_port   = lookup(var.database_inbound_acl_rules[count.index], "from_port", null)
  to_port     = lookup(var.database_inbound_acl_rules[count.index], "to_port", null)
  icmp_code   = lookup(var.database_inbound_acl_rules[count.index], "icmp_code", null)
  icmp_type   = lookup(var.database_inbound_acl_rules[count.index], "icmp_type", null)
  protocol    = var.database_inbound_acl_rules[count.index]["protocol"]
  cidr_block  = lookup(var.database_inbound_acl_rules[count.index], "cidr_block", null)
}

resource "aws_network_acl_rule" "database_outbound" {
  count = var.database_dedicated_network_acl && length(var.database_subnets) > 0 ? length(var.database_outbound_acl_rules) : 0

  network_acl_id = aws_network_acl.database[0].id

  egress      = true
  rule_number = var.database_outbound_acl_rules[count.index]["rule_number"]
  rule_action = var.database_outbound_acl_rules[count.index]["rule_action"]
  from_port   = lookup(var.database_outbound_acl_rules[count.index], "from_port", null)
  to_port     = lookup(var.database_outbound_acl_rules[count.index], "to_port", null)
  icmp_code   = lookup(var.database_outbound_acl_rules[count.index], "icmp_code", null)
  icmp_type   = lookup(var.database_outbound_acl_rules[count.index], "icmp_type", null)
  protocol    = var.database_outbound_acl_rules[count.index]["protocol"]
  cidr_block  = lookup(var.database_outbound_acl_rules[count.index], "cidr_block", null)
}