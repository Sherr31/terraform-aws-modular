# Data source for latest Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

# IAM Role for EC2 instances
resource "aws_iam_role" "this" {
  name               = var.instance_role_name
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = merge(var.tags, {
    Name      = var.instance_role_name
    ManagedBy = "Terraform"
    Module    = "autoscale"
  })
}

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# Attach ECR read-only policy to the instance role
resource "aws_iam_role_policy" "ecr_read_only" {
  name = "${var.instance_role_name}-ecr-read-only"
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ECRAuth"
        Effect   = "Allow"
        Action   = "ecr:GetAuthorizationToken"
        Resource = "*"
      },
      {
        Sid    = "ECRPull"
        Effect = "Allow"
        Action = [
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:DescribeImages",
          "ecr:DescribeRepositories"
        ]
        Resource = var.ecr_repository_arns
      }
    ]
  })


}

# Instance profile to attach role to EC2
resource "aws_iam_instance_profile" "this" {
  name = var.instance_profile_name
  role = aws_iam_role.this.name

  tags = merge(var.tags, {
    Name      = var.instance_profile_name
    ManagedBy = "Terraform"
    Module    = "autoscale"
  })
}

# Launch Template
resource "aws_launch_template" "this" {
  name_prefix   = "${var.name}-"
  image_id      = var.ami_id != null ? var.ami_id : data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.this.name
  }

  network_interfaces {
    associate_public_ip_address = var.associate_public_ip_address
    security_groups             = var.security_group_ids
  }

  monitoring {
    enabled = var.enhanced_monitoring
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size           = var.root_volume_size
      volume_type           = var.root_volume_type
      encrypted             = var.root_volume_encrypted
      delete_on_termination = true
    }
  }

  user_data = var.user_data != null ? var.user_data : base64encode(<<-EOT
    #!/bin/bash
    set -eux

    # Install Docker
    apt-get update
    apt-get install -y ca-certificates curl gnupg lsb-release

    install -m 0755 -d /etc/docker
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/docker/keyrings/docker.gpg
    chmod a+r /etc/docker/keyrings/docker.gpg

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/docker/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Configure Docker to start on boot
    systemctl enable docker
    systemctl start docker

    # Login to ECR
    aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${var.ecr_registry_id}.dkr.ecr.${var.aws_region}.amazonaws.com

    # Pull and run the application
    docker pull ${var.ecr_image_url}:${var.ecr_image_tag}
    docker stop app-container 2>/dev/null || true
    docker rm app-container 2>/dev/null || true
    docker run -d --name app-container --restart always -p 5000:5000 ${var.ecr_image_url}:${var.ecr_image_tag}

    # Enable HTTP traffic on port 5000
    ufw allow 5000/tcp || true
  EOT
  )

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name      = var.name
      ManagedBy = "Terraform"
      Module    = "autoscale"
    })
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "this" {
  name                = "${var.name}-asg"
  vpc_zone_identifier = var.subnet_ids
  target_group_arns   = var.target_group_arns
  min_size            = var.min_size
  max_size            = var.max_size
  desired_capacity    = var.desired_capacity

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  health_check_type         = "ELB"
  health_check_grace_period = 300
  default_cooldown          = 300
  wait_for_capacity_timeout = "10m"

  suspended_processes = []

  tag {
    key                 = "Name"
    value               = var.name
    propagate_at_launch = true
  }

  tag {
    key                 = "ManagedBy"
    value               = "Terraform"
    propagate_at_launch = true
  }

  tag {
    key                 = "Module"
    value               = "autoscale"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# CloudWatch metric alarm for high CPU
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  count               = var.cpu_alarm ? 1 : 0
  alarm_name          = "${var.name}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = var.cpu_threshold
  alarm_description   = "Scale up when EC2 CPU exceeds threshold"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.this.name
  }

  alarm_actions = var.alarm_actions

  tags = merge(var.tags, {
    Name      = "${var.name}-high-cpu"
    ManagedBy = "Terraform"
    Module    = "autoscale"
  })
}
