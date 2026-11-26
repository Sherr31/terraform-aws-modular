# examples/security-group/main.tf

terraform {
  required_version = ">= 1.5.0"

  # Optional: configure a remote backend for this example.
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "examples/security-group/terraform.tfstate"
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

module "web_security_group" {
  source = "../../modules/security-group"

  name        = "${var.name_prefix}-web-sg"
  description = "Security group for web servers"
  vpc_id      = var.vpc_id

  ingress_rules = var.ingress_rules

  egress_rules = var.egress_rules

  tags = merge(
    var.tags,
    {
      Purpose = "web"
    }
  )
}
