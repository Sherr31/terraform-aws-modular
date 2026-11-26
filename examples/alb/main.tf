# examples/alb/main.tf

terraform {
  required_version = ">= 1.5.0"

  # Optional: configure a remote backend for this example.
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "examples/alb/terraform.tfstate"
  #   region         = "us-east-1"
  #   use_lockfile   = true
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

module "alb" {
  source = "../../modules/alb"

  name_prefix = var.name_prefix

  subnet_ids = var.subnet_ids
  vpc_id     = var.vpc_id

  internal = var.internal

  create_security_group = var.create_security_group
  security_group_id     = var.security_group_id

  alb_ingress_rules = var.alb_ingress_rules
  alb_egress_rules  = var.alb_egress_rules

  ip_address_type            = var.ip_address_type
  enable_deletion_protection = var.enable_deletion_protection

  listener_port     = var.listener_port
  listener_protocol = var.listener_protocol

  target_group_port     = var.target_group_port
  target_group_protocol = var.target_group_protocol
  target_type           = var.target_type

  health_check_path          = var.health_check_path
  health_check_protocol      = var.health_check_protocol
  health_check_port          = var.health_check_port
  health_check_interval      = var.health_check_interval
  health_check_timeout       = var.health_check_timeout
  health_healthy_threshold   = var.health_healthy_threshold
  health_unhealthy_threshold = var.health_unhealthy_threshold
  health_check_matcher       = var.health_check_matcher

  tags = merge(
    var.tags,
    {
      Purpose = "alb"
    }
  )
}
