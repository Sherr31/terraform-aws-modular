# bootstrap/terraform-state/main.tf
#
# Creates the S3 bucket and DynamoDB table used for Terraform remote state.
#
# This bootstrap configuration must NOT use the S3 backend it creates.
# Initially use local state or another separately established backend.
#
# IMPORTANT: Protect this state. It manages the state storage for everything
# else in the project.

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 6.0"
    }
  }

  # This bootstrap uses local state initially.
  # After the S3 bucket is created, you can optionally migrate to it,
  # but the bootstrap should not depend on itself.
  # backend "s3" {
  #   bucket = "your-terraform-state-bucket"
  #   key    = "bootstrap/terraform-state/terraform.tfstate"
  #   region = "us-east-1"
  #   encrypt = true
  #   use_lockfile = true
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Purpose     = "terraform-state-infrastructure"
    }
  }
}

# -----------------------------------------------------------------------------
# S3 bucket for Terraform state
# -----------------------------------------------------------------------------

resource "aws_s3_bucket" "terraform_state" {
  bucket        = var.bucket_name
  force_destroy = var.force_destroy
}

# -----------------------------------------------------------------------------
# Block all public access — state must never be public
# -----------------------------------------------------------------------------

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# -----------------------------------------------------------------------------
# Server-side encryption — encrypt state at rest
# -----------------------------------------------------------------------------

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# -----------------------------------------------------------------------------
# Versioning — protect against accidental deletion or corruption
# -----------------------------------------------------------------------------

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# -----------------------------------------------------------------------------
# Lifecycle — clean up old versions to control costs
# -----------------------------------------------------------------------------

resource "aws_s3_bucket_lifecycle_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    id     = "delete-old-versions"
    status = "Enabled"
    filter {
      prefix = ""
    }

    # Keep only the last 10 versions of each object
    # This prevents unlimited growth from state file revisions
    expiration {
      days = 365
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

# -----------------------------------------------------------------------------
# DynamoDB table for state locking
# -----------------------------------------------------------------------------

resource "aws_dynamodb_table" "terraform_locks" {
  name         = var.lock_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  # Tags
  tags = merge(
    var.tags,
    {
      Name = var.lock_table_name
    }
  )
}

# -----------------------------------------------------------------------------
# Enforce HTTPS-only access
# -----------------------------------------------------------------------------
# Deny all S3 operations unless the request is made over HTTPS.
# This protects state data in transit even if a client has valid IAM
# credentials, by blocking any non-encrypted transport.
# -----------------------------------------------------------------------------

resource "aws_s3_bucket_policy" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnforceHTTPS"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.terraform_state.arn,
          "${aws_s3_bucket.terraform_state.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# IAM policy — least-privilege access for Terraform to use the state bucket
# -----------------------------------------------------------------------------

resource "aws_iam_policy" "terraform_state_access" {
  count = var.create_access_policy ? 1 : 0

  name        = "${var.bucket_name}-access-policy"
  description = "IAM policy for accessing the Terraform state bucket and lock table."
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowStateBucketAccess"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = aws_s3_bucket.terraform_state.arn
      },
      {
        Sid    = "AllowStateObjectAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${aws_s3_bucket.terraform_state.arn}/*"
      },
      {
        Sid    = "AllowStateLocking"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem"
        ]
        Resource = aws_dynamodb_table.terraform_locks.arn
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.bucket_name}-access-policy"
    }
  )
}
