
# Ubuntu 24.04 AMI
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
      description = "HTTP from internet"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  tags = var.tags
}

# EC2 Security Group
module "ec2_security_group" {
  source = "../../modules/security-group"

  name        = "${var.app_name}-ec2-sg"
  description = "Allow web traffic within VPC"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = [
    {
      description = "HTTP from VPC"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = [var.vpc_cidr]
    }
  ]

  tags = var.tags
}

# RDS Security Group
module "rds_security_group" {
  source = "../../modules/security-group"

  name        = "${var.app_name}-rds-sg"
  description = "Database access security group"
  vpc_id      = module.vpc.vpc_id

  tags = var.tags
}

# Allow PostgreSQL traffic only from the EC2 security group
resource "aws_security_group_rule" "rds_from_ec2" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = module.rds_security_group.security_group_id
  source_security_group_id = module.ec2_security_group.security_group_id
  description              = "PostgreSQL access from application EC2"
}

# EC2 Web Server
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
    apt-get update
    apt-get install -y nginx
    systemctl enable nginx
    systemctl start nginx
  EOF

  tags = var.tags
}

# Application Load Balancer
module "alb" {
  source = "../../modules/alb"

  name               = "${var.app_name}-alb"
  internal           = false
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.public_subnet_ids
  security_group_ids = [module.alb_security_group.security_group_id]

  target_port       = 80
  health_check_path = "/"

  tags = var.tags
}

# Attach EC2 to ALB
resource "aws_lb_target_group_attachment" "ec2" {
  target_group_arn = module.alb.target_group_arn
  target_id        = module.ec2.instance_id
  port             = 80
}

# PostgreSQL RDS Database
module "rds" {
  source = "../../modules/rds"

  identifier     = var.db_identifier
  engine         = "postgres"
  engine_version = "16"
  instance_class = "db.t3.micro"

  allocated_storage     = 20
  max_allocated_storage = 100

  db_name  = "appdb"
  username = "dbadmin"

  subnet_ids = module.vpc.private_subnet_ids

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

# S3 Storage
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
