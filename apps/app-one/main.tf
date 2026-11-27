
# Latest Ubuntu 24.04 AMI
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

# VPC
module "vpc" {
  source = "../../modules/vpc"

  name                 = var.app_name
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs

  enable_nat_gateway = false

  tags = var.tags
}

# ALB Security Group
module "alb_security_group" {
  source = "../../modules/security-group"

  name        = "${var.app_name}-alb-sg"
  description = "Allow HTTP traffic to the ALB"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = [
    {
      description = "Allow HTTP traffic"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  egress_rules = [
    {
      description = "Allow outbound traffic"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  tags = var.tags
}

# EC2 Security Group
module "ec2_security_group" {
  source = "../../modules/security-group"

  name        = "${var.app_name}-ec2-sg"
  description = "Allow HTTP traffic from within the VPC"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = [
    {
      description = "Allow HTTP traffic from VPC"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = [var.vpc_cidr]
    }
  ]

  egress_rules = [
    {
      description = "Allow outbound traffic"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  tags = var.tags
}

# --- App One Target Group (port 5000) ---

resource "aws_lb_target_group" "app_one" {
  name        = "${var.app_name}-tg"
  port        = 5000
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200-399"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 5
  }

  tags = merge(var.tags, {
    Name      = "${var.app_name}-tg"
    ManagedBy = "Terraform"
    Module    = "app-one"
  })
}

# EC2 Instance (runs Docker container)
module "ec2" {
  source = "../../modules/ec2"

  name               = "${var.app_name}-web-server"
  ami_id             = data.aws_ami.ubuntu.id
  instance_type      = var.instance_type
  subnet_id          = module.vpc.public_subnet_ids[0]
  security_group_ids = [module.ec2_security_group.security_group_id]

  key_name                    = var.key_name
  associate_public_ip_address = true

  user_data = <<-EOF
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

    systemctl enable docker
    systemctl start docker

    # Login to ECR
    aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${var.aws_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com

    # Pull and run App One
    docker pull ${var.ecr_repository_url}:${var.ecr_image_tag}
    docker stop app-one-container 2>/dev/null || true
    docker rm app-one-container 2>/dev/null || true
    docker run -d --name app-one-container --restart always -p 5000:5000 ${var.ecr_repository_url}:${var.ecr_image_tag}
  EOF

  tags = var.tags
}

# Application Load Balancer with path-based routing
module "alb" {
  source = "../../modules/alb"

  name               = "${var.app_name}-alb"
  internal           = false
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.public_subnet_ids
  security_group_ids = [module.alb_security_group.security_group_id]

  target_port       = 5000
  health_check_path = "/health"

  path_rules = [
    {
      priority         = 10
      paths            = ["/app-one/*"]
      target_group_arn = aws_lb_target_group.app_one.arn
    },
    {
      priority         = 20
      paths            = ["/app-two/*"]
      target_group_arn = var.app_two_target_group_arn
    }
  ]

  tags = var.tags
}

# Register EC2 with ALB Target Group
resource "aws_lb_target_group_attachment" "ec2" {
  target_group_arn = aws_lb_target_group.app_one.arn
  target_id        = module.ec2.instance_id
  port             = 5000
}

# S3 Bucket
module "s3" {
  source = "../../modules/s3"

  bucket_name        = var.bucket_name
  versioning_enabled = true
  force_destroy      = false

  tags = var.tags
}

# ECR Repository
module "ecr" {
  source = "../../modules/ecr"

  repository_name      = var.ecr_repository_name
  image_tag_mutability = "IMMUTABLE"
  scan_on_push         = true
  force_delete         = false

  tags = var.tags
}
