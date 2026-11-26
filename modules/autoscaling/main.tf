# main.tf — reusable Auto Scaling module

# -----------------------------------------------------------------------------
# IAM Instance Profile — for EC2 instances to assume a role
# -----------------------------------------------------------------------------

resource "aws_iam_instance_profile" "this" {
  count = var.create_iam_instance_profile ? 1 : 0

  name = var.instance_profile_name != null ? var.instance_profile_name : "${var.name_prefix != null ? var.name_prefix : "asg"}-profile"
  role = var.iam_role_name

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Launch Template — defines how instances are created
# -----------------------------------------------------------------------------

resource "aws_launch_template" "this" {
  name_prefix   = var.name_prefix != null ? "${var.name_prefix}-" : null
  image_id      = var.ami
  instance_type = var.instance_type

  # Network settings — simplified: use the first subnet and security groups
  network_interfaces {
    associate_public_ip_address = var.associate_public_ip
    security_groups             = var.security_group_ids
    subnet_id                   = var.subnet_ids[0]
    delete_on_termination       = true
    device_index                = 0
  }

  # IAM — use name or ARN whichever is provided
  iam_instance_profile {
    name = var.instance_profile_name != null ? var.instance_profile_name : (var.create_iam_instance_profile ? aws_iam_instance_profile.this[0].name : null)
    arn  = var.iam_instance_profile_arn
  }

  # Storage
  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = var.root_volume_size
      volume_type           = var.root_volume_type
      encrypted             = var.root_volume_encrypted
      delete_on_termination = var.root_delete_on_termination
      iops                  = var.root_volume_iops
      throughput            = var.root_volume_throughput
    }
  }

  # Metadata
  metadata_options {
    http_tokens                 = var.imdsv2_required ? "required" : "optional"
    http_endpoint               = "enabled"
    http_put_response_hop_limit = var.http_put_response_hop_limit
  }

  # Tagging
  tag_specifications {
    resource_type = "instance"

    tags = merge(
      var.tags,
      {
        Name = var.name_prefix != null ? "${var.name_prefix}-instance" : "asg-instance"
      }
    )
  }

  # Optional user data
  user_data = var.user_data != null ? base64encode(var.user_data) : null

  # Optional key pair
  key_name = var.key_name

  # Optional monitoring
  monitoring {
    enabled = var.enhanced_monitoring
  }
}

# -----------------------------------------------------------------------------
# Auto Scaling Group — manages the fleet of instances
# -----------------------------------------------------------------------------

resource "aws_autoscaling_group" "this" {
  name                      = var.name_prefix != null ? "${var.name_prefix}-asg" : "asg"
  vpc_zone_identifier       = var.subnet_ids
  target_group_arns         = var.target_group_arns
  health_check_type         = var.health_check_type
  health_check_grace_period = var.health_check_grace_period

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  # Instance refresh
  instance_refresh {
    strategy = var.instance_refresh_strategy
    preferences {
      min_healthy_percentage = var.instance_refresh_min_healthy_percentage
      auto_rollback          = var.instance_refresh_auto_rollback
    }
  }

  # Tags
  tag {
    key                 = "Name"
    value               = var.name_prefix != null ? "${var.name_prefix}-instance" : "asg-instance"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.extra_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  # Launch template
  launch_template {
    id      = aws_launch_template.this.id
    version = "$Default"
  }

  # Termination policies
  termination_policies = var.termination_policies

  # Wait for capacity
  wait_for_capacity_timeout = var.wait_for_capacity_timeout

  # Capacity rebalance
  capacity_rebalance = var.capacity_rebalance


  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_capacity]
  }
}

# -----------------------------------------------------------------------------
# Scaling policies — optional, for dynamic scaling
# -----------------------------------------------------------------------------

# Scaling policies are optional
# Use aws_autoscaling_policy resources in the root configuration
# for more complex scaling behavior.
# This module provides basic scaling via min_size, max_size, desired_capacity.
