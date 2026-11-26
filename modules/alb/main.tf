# main.tf — reusable ALB module

# -----------------------------------------------------------------------------
# Security group for the ALB — optional, created if not provided
# -----------------------------------------------------------------------------

resource "aws_security_group" "alb" {
  count = var.create_security_group && var.security_group_id == null ? 1 : 0

  name        = "${var.name_prefix}-alb-sg"
  description = "Security group for ${var.name_prefix} ALB"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.alb_ingress_rules
    content {
      description      = ingress.value.description
      protocol         = ingress.value.protocol
      from_port        = ingress.value.from_port
      to_port          = ingress.value.to_port
      cidr_blocks      = ingress.value.cidr_blocks
      ipv6_cidr_blocks = ingress.value.ipv6_cidr_blocks
      self             = ingress.value.self
    }
  }

  dynamic "egress" {
    for_each = var.alb_egress_rules
    content {
      description      = egress.value.description
      protocol         = egress.value.protocol
      from_port        = egress.value.from_port
      to_port          = egress.value.to_port
      cidr_blocks      = egress.value.cidr_blocks
      ipv6_cidr_blocks = egress.value.ipv6_cidr_blocks
      self             = egress.value.self
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-alb-sg"
    }
  )
}

# -----------------------------------------------------------------------------
# Application Load Balancer
# -----------------------------------------------------------------------------

resource "aws_lb" "this" {
  name               = var.name_prefix != null ? "${var.name_prefix}-alb" : null
  internal           = var.internal
  load_balancer_type = "application"
  security_groups    = var.security_group_id != null ? [var.security_group_id] : [var.create_security_group ? aws_security_group.alb[0].id : null]
  subnets            = var.subnet_ids
  ip_address_type    = var.ip_address_type

  enable_deletion_protection = var.enable_deletion_protection

  tags = merge(
    var.tags,
    {
      Name = var.name_prefix != null ? "${var.name_prefix}-alb" : "alb"
    }
  )
}

# -----------------------------------------------------------------------------
# Default target group — basic group for health checks
# -----------------------------------------------------------------------------

resource "aws_lb_target_group" "this" {
  name        = var.target_group_name != null ? var.target_group_name : "${var.name_prefix}-tg"
  port        = var.target_group_port
  protocol    = var.target_group_protocol
  vpc_id      = var.vpc_id
  target_type = var.target_type

  health_check {
    enabled             = var.health_check_enabled
    path                = var.health_check_path
    port                = var.health_check_port
    protocol            = var.health_check_protocol
    interval            = var.health_check_interval
    timeout             = var.health_check_timeout
    healthy_threshold   = var.health_healthy_threshold
    unhealthy_threshold = var.health_unhealthy_threshold
    matcher             = var.health_check_matcher
  }

  tags = merge(
    var.tags,
    {
      Name = var.target_group_name != null ? var.target_group_name : "${var.name_prefix}-tg"
    }
  )
}

# -----------------------------------------------------------------------------
# Listener — forwards traffic to the target group
# -----------------------------------------------------------------------------

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = var.listener_port
  protocol          = var.listener_protocol

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-http-listener"
    }
  )
}
