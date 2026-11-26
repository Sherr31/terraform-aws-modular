# main.tf — reusable security group module

# -----------------------------------------------------------------------------
# Security Group — controls traffic to and from AWS resources
# -----------------------------------------------------------------------------

resource "aws_security_group" "this" {
  name                   = var.name
  description            = var.description
  vpc_id                 = var.vpc_id
  revoke_rules_on_delete = var.revoke_rules_on_delete

  tags = merge(
    var.tags,
    {
      Name = var.name
    }
  )
}

# -----------------------------------------------------------------------------
# Ingress rules — traffic allowed INTO the resource
# -----------------------------------------------------------------------------

resource "aws_security_group_rule" "ingress_rules" {
  for_each = { for idx, rule in var.ingress_rules : "${idx}" => rule }

  security_group_id        = aws_security_group.this.id
  type                     = "ingress"
  protocol                 = each.value.protocol
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  cidr_blocks              = each.value.cidr_blocks
  ipv6_cidr_blocks         = each.value.ipv6_cidr_blocks
  prefix_list_ids          = each.value.prefix_list_ids
  source_security_group_id = each.value.security_groups
  description              = lookup(each.value, "description", "")
  self                     = each.value.self
}

# -----------------------------------------------------------------------------
# Egress rules — traffic allowed OUT OF the resource
# -----------------------------------------------------------------------------

resource "aws_security_group_rule" "egress_rules" {
  for_each = { for idx, rule in var.egress_rules : "${idx}" => rule }

  security_group_id        = aws_security_group.this.id
  type                     = "egress"
  protocol                 = each.value.protocol
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  cidr_blocks              = each.value.cidr_blocks
  ipv6_cidr_blocks         = each.value.ipv6_cidr_blocks
  prefix_list_ids          = each.value.prefix_list_ids
  source_security_group_id = each.value.security_groups
  description              = lookup(each.value, "description", "")
  self                     = each.value.self
}
