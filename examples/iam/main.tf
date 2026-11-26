# examples/iam/main.tf

terraform {
  required_version = ">= 1.5.0"

  # Optional: configure a remote backend for this example.
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "examples/iam/terraform.tfstate"
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

module "iam_role" {
  source = "../../modules/iam"

  role_name = var.role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = var.assume_role_service
        }
      }
    ]
  })

  create_policy = var.create_policy

  policy_document = jsonencode({
    Version   = "2012-10-17"
    Statement = var.policy_statements
  })

  policy_name        = var.policy_name
  policy_description = var.policy_description

  create_instance_profile = var.create_instance_profile

  max_session_duration = var.max_session_duration

  tags = merge(
    var.tags,
    {
      Purpose = var.role_purpose
    }
  )
}
