# examples/ecr/variables.tf

variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short project name used in default provider tags."
  type        = string
  default     = "ecr-example"
}

variable "environment" {
  description = "Environment label."
  type        = string
  default     = "dev"
}

variable "repository_name" {
  description = "Name of the ECR repository. Must be unique in the account and region."
  type        = string
  default     = "ecr-example-repo"
}

variable "repository_purpose" {
  description = "Purpose label for the repository (used in tags)."
  type        = string
  default     = "example"
}

# -----------------------------------------------------------------------------
# Image settings
# -----------------------------------------------------------------------------

variable "image_tag_mutability" {
  description = "Image tag mutability: MUTABLE or IMMUTABLE."
  type        = string
  default     = "MUTABLE"
}

variable "scan_on_push" {
  description = "Scan images for vulnerabilities on push."
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Encryption
# -----------------------------------------------------------------------------

variable "encryption_type" {
  description = "Encryption type: AES256 or aws:kms."
  type        = string
  default     = "AES256"
}

variable "kms_key_id" {
  description = "KMS key ID for aws:kms encryption. Ignored for AES256."
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# Lifecycle policy
# -----------------------------------------------------------------------------

variable "lifecycle_policy" {
  description = "Lifecycle policy for image cleanup. Leave null to skip."
  type = object({
    rules = list(object({
      rulePriority = number
      description  = string
      selection = object({
        tagStatus   = string
        countType   = string
        countNumber = optional(number)
        countUnit   = optional(string)
      })
      action = object({
        type = string
      })
    }))
  })
  default = {
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  }
}

# -----------------------------------------------------------------------------
# Repository policy
# -----------------------------------------------------------------------------

variable "repository_policy" {
  description = "Repository policy for access control. Leave null to skip."
  type = object({
    Version = string
    Statement = list(object({
      Sid       = optional(string)
      Effect    = string
      Principal = any
      Action    = list(string)
      Resource  = string
      Condition = optional(any)
    }))
  })
  default = null
}

variable "tags" {
  description = "Additional tags to apply to the repository."
  type        = map(string)
  default     = {}
}
