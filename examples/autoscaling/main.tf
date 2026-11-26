# examples/autoscaling/main.tf

terraform {
  required_version = ">= 1.5.0"

  # Optional: configure a remote backend for this example.
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "examples/autoscaling/terraform.tfstate"
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

module "asg" {
  source = "../../modules/autoscaling"

  name_prefix   = var.name_prefix
  ami           = var.ami
  instance_type = var.instance_type

  subnet_ids = var.subnet_ids


  security_group_ids = var.security_group_ids

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  health_check_type         = var.health_check_type
  health_check_grace_period = var.health_check_grace_period

  target_group_arns = var.target_group_arns

  root_volume_size      = var.root_volume_size
  root_volume_type      = var.root_volume_type
  root_volume_encrypted = var.root_volume_encrypted

  imdsv2_required     = var.imdsv2_required
  enhanced_monitoring = var.enhanced_monitoring

  user_data = var.user_data
  key_name  = var.key_name

  termination_policies = var.termination_policies

  tags = merge(
    var.tags,
    {
      Purpose = "asg"
    }
  )
}
