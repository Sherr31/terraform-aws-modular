
resource "aws_lb" "this" {
  name               = var.name
  internal           = var.internal
  load_balancer_type = "application"
  security_groups    = var.security_group_ids
  subnets            = var.subnet_ids

  enable_deletion_protection = false

  tags = merge(var.tags, {
    Name      = var.name
    ManagedBy = "Terraform"
    Module    = "alb"
  })
}

resource "aws_lb_target_group" "this" {
  name        = "${var.name}-tg"
  port        = var.target_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    path                = var.health_check_path
    protocol            = "HTTP"
    matcher             = "200-399"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 5
  }

  tags = merge(var.tags, {
    Name      = "${var.name}-tg"
    ManagedBy = "Terraform"
    Module    = "alb"
  })
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = "404"
    }
  }
}

# Path-based routing rules
resource "aws_lb_listener_rule" "path_rules" {
  for_each = { for idx, rule in var.path_rules : idx => rule }

  listener_arn = aws_lb_listener.http.arn
  priority    = each.value.priority

  action {
    type             = "forward"
    target_group_arn = each.value.target_group_arn
  }

  condition {
    path_pattern {
      values = each.value.paths
    }
  }

  tags = merge(var.tags, {
    Name      = "${var.name}-rule-${each.key}"
    ManagedBy = "Terraform"
    Module    = "alb"
  })
}

# Default target group attachment (optional, for non-matched traffic)
resource "aws_lb_target_group_attachment" "default" {
  count = var.default_target_id != null ? 1 : 0

  target_group_arn = var.target_group_arns[0]
  target_id        = var.default_target_id
  port             = var.target_port
}
