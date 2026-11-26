# apps/infrastructure-lab/main.tf
#
# Integrated AWS application combining VPC, Security Groups, ALB, and ASG.
#
# Architecture:
#
#   Internet
#      │
#      ▼
#   [Public ALB] ──▶ [Private EC2 instances in ASG]
#      │                  │
#      │                  ▼
#      │            [Private Subnet]
#      │                  │
#      │                  ▼
#      │            [No NAT Gateway — instances have no internet access]
#      │
#      ▼
#   [Public Subnet] ──▶ [Internet Gateway]
#
# Cost notes:
#   - No NAT Gateway (saves ~$33/month + EIP + data processing)
#   - EC2 instances are t3.micro (free tier eligible)
#   - ALB costs ~$16/month + LCU charges
#   - Total for a minimal deployment: ~$17-25/month

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = merge(
      var.tags,
      {
        Project     = "infrastructure-lab"
        Environment = var.environment
        ManagedBy   = "terraform"
      }
    )
  }
}

# -----------------------------------------------------------------------------
# User data — bootstraps each EC2 instance with a simple Python HTTP server
# -----------------------------------------------------------------------------
#
# This script runs on every instance launch. It:
#   1. Installs Python (if not already present)
#   2. Creates a simple HTTP server script
#   3. Starts the server on the configured app port
#   4. Sets up a health endpoint at /
#
# The ALB health check hits / and expects HTTP 200.

locals {
  user_data = <<-EOT
    #!/bin/bash
    set -e

    # Install Python if not present (Amazon Linux 2023 includes it, but be safe)
    if ! command -v python3 &> /dev/null; then
      dnf install -y python3
    fi

    # Create the application directory
    mkdir -p /app

    # Write the application
    cat > /app/server.py << 'PYEOF'
    import http.server
    import json
    import platform
    import os

    class AppHandler(http.server.BaseHTTPRequestHandler):
        def do_GET(self):
            if self.path == "/health" or self.path == "/":
                self.send_response(200)
                self.send_header("Content-Type", "application/json")
                self.end_headers()
                response = {
                    "status": "healthy",
                    "instance_id": os.environ.get("INSTANCE_ID", "unknown"),
                    "hostname": platform.node(),
                    "region": os.environ.get("AWS_REGION", "unknown")
                }
                self.wfile.write(json.dumps(response, indent=2).encode())
            else:
                self.send_response(404)
                self.send_header("Content-Type", "application/json")
                self.end_headers()
                self.wfile.write(json.dumps({"error": "not found"}).encode())

        def log_message(self, format, *args):
            # Suppress default logging to keep instance logs clean
            pass

    if __name__ == "__main__":
        port = int(os.environ.get("APP_PORT", "8080"))
        server = http.server.HTTPServer(("0.0.0.0", port), AppHandler)
        print(f"Starting server on port {port}")
        server.serve_forever()
    PYEOF

    # Start the server as a background process
    export APP_PORT="${var.app_port}"
    export INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null || echo "unknown")
    export AWS_REGION="${var.aws_region}"

    nohup python3 /app/server.py > /var/log/app-server.log 2>&1 &
    echo $! > /var/run/app-server.pid

    # Keep the script alive so the instance doesn't exit
    wait
  EOT
}

# -----------------------------------------------------------------------------
# VPC — network foundation
# -----------------------------------------------------------------------------
#
# Creates the VPC, public subnets, private subnets, internet gateway, and
# route tables. No NAT Gateway (cost savings).

module "vpc" {
  source = "../../modules/vpc"

  name_prefix          = var.name_prefix
  cidr_block           = var.vpc_cidr_block
  az_count             = var.az_count
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  enable_nat_gateway   = false
  tags                 = var.tags
}

# -----------------------------------------------------------------------------
# ALB Security Group — allows HTTP from the internet
# -----------------------------------------------------------------------------
#
# This security group is created by the ALB module. We reference it later
# in the app security group to allow only the ALB to reach the instances.

module "alb" {
  source = "../../modules/alb"

  name_prefix       = "${var.name_prefix}-alb"
  subnet_ids        = module.vpc.public_subnet_ids
  vpc_id            = module.vpc.vpc_id
  internal          = false
  listener_port     = var.alb_listener_port
  target_group_port = var.app_port
  health_check_path = "/health"
  alb_ingress_rules = [
    {
      description = "HTTP from internet"
      protocol    = "tcp"
      from_port   = var.alb_listener_port
      to_port     = var.alb_listener_port
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-alb-sg"
  })
}

# -----------------------------------------------------------------------------
# Application Security Group — allows traffic only from the ALB
# -----------------------------------------------------------------------------
#
# This is the key security control: instances are unreachable from the
# internet. Only the ALB security group can talk to them on the app port.

module "app_security_group" {
  source = "../../modules/security-group"

  name        = "${var.name_prefix}-app-sg"
  description = "Security group for application instances. Only accessible from the ALB."
  vpc_id      = module.vpc.vpc_id
  ingress_rules = [
    {
      description     = "HTTP from ALB"
      protocol        = "tcp"
      from_port       = var.app_port
      to_port         = var.app_port
      cidr_blocks     = []
      security_groups = [module.alb.security_group_id]
    }
  ]
  egress_rules = [
    {
      description = "Allow all outbound"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-app-sg"
  })
}

# -----------------------------------------------------------------------------
# Auto Scaling Group — manages EC2 instances
# -----------------------------------------------------------------------------
#
# Instances are placed in private subnets. They have no public IP.
# The ALB routes traffic to them via the target group.
# Health checks use ELB mode — the ALB determines instance health.

module "asg" {
  source = "../../modules/autoscaling"

  name_prefix                 = var.name_prefix
  subnet_ids                  = module.vpc.private_subnet_ids
  security_group_ids          = [module.app_security_group.security_group_id]
  associate_public_ip         = false
  ami                         = var.ami
  instance_type               = var.instance_type
  min_size                    = var.asg_min_size
  max_size                    = var.asg_max_size
  desired_capacity            = var.asg_desired_capacity
  root_volume_size            = 8
  root_volume_type            = "gp3"
  root_volume_encrypted       = true
  imdsv2_required             = true
  http_put_response_hop_limit = 1
  user_data                   = base64encode(local.user_data)
  health_check_type           = "ELB"
  health_check_grace_period   = 60
  target_group_arns           = [module.alb.target_group_arn]
  instance_refresh_strategy   = "Rolling"
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-asg"
  })
}
