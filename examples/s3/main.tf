# examples/s3/main.tf

terraform {
  required_version = ">= 1.5.0"

  # Optional: configure a remote backend for this example.
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "examples/s3/terraform.tfstate"
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

module "s3_bucket" {
  source = "../../modules/s3"

  bucket_name        = var.bucket_name
  versioning_enabled = var.versioning_enabled
  sse_algorithm      = var.sse_algorithm
  kms_key_id         = var.kms_key_id
  object_ownership   = var.object_ownership
  acl                = var.acl

  tags = merge(
    var.tags,
    {
      Purpose = var.bucket_purpose
    }
  )

  lifecycle_rules = var.lifecycle_rules
}
