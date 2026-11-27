
# --- Shared VPC Reference (App One VPC) ---

# Fetch the existing app-one VPC
data "aws_vpc" "app_one_vpc" {
  filter {
    name   = "tag:Project"
    values = ["terraform-aws-modular"]
  }

  filter {
    name   = "tag:Name"
    values = ["app-one-vpc"]
  }
}

# Fetch existing public subnets in the app-one VPC
data "aws_subnets" "app_one_public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.app_one_vpc.id]
  }

  filter {
    name   = "tag:Name"
    values = ["app-one-public-1", "app-one-public-2"]
  }
}

# Fetch existing private subnets
data "aws_subnets" "app_one_private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.app_one_vpc.id]
  }

  filter {
    name   = "tag:Name"
    values = ["app-one-private-1", "app-one-private-2"]
  }
}

# Fetch the existing ALB
data "aws_lb" "app_one_alb" {
  name = "app-one-alb"
}

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

# --- Security Groups (in app-one VPC) ---

# ALB Security Group (reuse existing or create new)
module "alb_security_group" {
  source = "../../modules/security-group"

  name        = "${var.app_name}-alb-sg"
  description = "Allow HTTP traffic to the shared ALB"
  vpc_id      = data.aws_vpc.app_one_vpc.id

  ingress_rules = [
    {
      description = "HTTP from internet"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  egress_rules = [
    {
      description = "Allow all outbound"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  tags = var.tags
}

# EC2/ASG Security Group
module "app_security_group" {
  source = "../../modules/security-group"

  name        = "${var.app_name}-app-sg"
  description = "Allow traffic from ALB to application"
  vpc_id      = data.aws_vpc.app_one_vpc.id

  ingress_rules = [
    {
      description  = "HTTP from ALB"
      from_port    = 5000
      to_port      = 5000
      protocol     = "tcp"
      cidr_blocks  = []
      source_sg_id = tolist(data.aws_lb.app_one_alb.security_groups)[0]
    }
  ]

  egress_rules = [
    {
      description = "Allow all outbound"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description  = "PostgreSQL from RDS"
      from_port    = 5432
      to_port      = 5432
      protocol     = "tcp"
      cidr_blocks  = []
      source_sg_id = module.rds_security_group.security_group_id
    }
  ]

  tags = var.tags
}

# RDS Security Group
module "rds_security_group" {
  source = "../../modules/security-group"

  name        = "${var.app_name}-rds-sg"
  description = "Database access security group"
  vpc_id      = data.aws_vpc.app_one_vpc.id

  tags = var.tags
}

# Allow PostgreSQL traffic from app-two security group
resource "aws_security_group_rule" "rds_from_app_two" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = module.rds_security_group.security_group_id
  source_security_group_id = module.app_security_group.security_group_id
  description              = "PostgreSQL access from app-two application"
}

# --- ECR Repository ---

module "ecr" {
  source = "../../modules/ecr"

  repository_name      = var.ecr_repository_name
  image_tag_mutability = "IMMUTABLE"
  scan_on_push         = true
  force_delete         = false

  tags = var.tags
}

# --- Auto Scaling Group ---

module "autoscale" {
  source = "../../modules/autoscale"

  name               = var.app_name
  ami_id             = data.aws_ami.ubuntu.id
  instance_type      = var.instance_type
  subnet_ids         = data.aws_subnets.app_one_public.ids
  security_group_ids = [module.app_security_group.security_group_id]

  ecr_registry_id = module.ecr.registry_id
  ecr_image_url   = module.ecr.repository_url
  ecr_image_tag   = var.ecr_image_tag
  aws_region      = "us-east-1"

  min_size         = 1
  max_size         = 2
  desired_capacity = 1

  target_group_arns   = [aws_lb_target_group.app_two.arn]
  enhanced_monitoring = true

  tags = var.tags
}

# --- Shared ALB Target Group for App Two ---

resource "aws_lb_target_group" "app_two" {
  name        = "${var.app_name}-tg"
  port        = 5000
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.app_one_vpc.id
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
    Module    = "app-two"
  })
}

# --- RDS PostgreSQL ---

module "rds" {
  source = "../../modules/rds"

  identifier     = var.db_identifier
  engine         = "postgres"
  engine_version = "16"
  instance_class = "db.t3.micro"

  allocated_storage     = 20
  max_allocated_storage = 100

  db_name  = var.db_name
  username = var.db_username

  subnet_ids = data.aws_subnets.app_one_private.ids

  vpc_security_group_ids = [
    module.rds_security_group.security_group_id
  ]

  backup_retention_period = 7
  publicly_accessible     = false
  storage_encrypted       = true
  deletion_protection     = true

  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.db_identifier}-final"

  tags = var.tags
}

# --- S3 Bucket ---

module "s3" {
  source = "../../modules/s3"

  bucket_name        = var.bucket_name
  versioning_enabled = true
  force_destroy      = false

  tags = var.tags
}
