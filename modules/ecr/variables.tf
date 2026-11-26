# variables.tf — inputs for the reusable ECR repository module

# -----------------------------------------------------------------------------
# Repository name
# -----------------------------------------------------------------------------

variable "repository_name" {
  description = <<-EOT
    Name of the ECR repository.

    Repository names must be unique within the AWS account and region.
    Use descriptive names that include the project and purpose.
  EOT
  type        = string
}

# -----------------------------------------------------------------------------
# Image tag mutability
# -----------------------------------------------------------------------------

variable "image_tag_mutability" {
  description = <<-EOT
    Image tag mutability setting.

    - "MUTABLE" (default) — tags can be overwritten (e.g. pushing "latest" again)
    - "IMMUTABLE" — tags cannot be overwritten once pushed

    Use "IMMUTABLE" for production to prevent accidental overwrites.
  EOT
  type        = string
  default     = "MUTABLE"

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "image_tag_mutability must be 'MUTABLE' or 'IMMUTABLE'."
  }
}

# -----------------------------------------------------------------------------
# Image scanning
# -----------------------------------------------------------------------------

variable "scan_on_push" {
  description = <<-EOT
    Enable vulnerability scanning on image push.

    When true, ECR scans images for CVEs after each push and reports
    findings in the console and via event notifications.

    Scanning is free, but review findings and patch images regularly.
  EOT
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Encryption
# -----------------------------------------------------------------------------

variable "encryption_type" {
  description = <<-EOT
    Encryption type for the repository.

    - "AES256" (default) — S3-managed encryption keys
    - "aws:kms" — AWS KMS keys (requires kms_key_id if using a custom key)
  EOT
  type        = string
  default     = "AES256"

  validation {
    condition     = contains(["AES256", "aws:kms"], var.encryption_type)
    error_message = "encryption_type must be 'AES256' or 'aws:kms'."
  }
}

variable "kms_key_id" {
  description = <<-EOT
    KMS key ID for encryption when encryption_type is "aws:kms".

    Ignored when encryption_type is "AES256".

    Leave null to use the default ECR KMS key (aws/ecr).
  EOT
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# Lifecycle policy
# -----------------------------------------------------------------------------

variable "lifecycle_policy" {
  description = <<-EOT
    Lifecycle policy for the repository.

    Use lifecycle policies to manage image cleanup and control storage costs.
    Images that are no longer needed consume storage and cost money.

    Example — keep only the 10 most recent images:

    ```hcl
    lifecycle_policy = {
      rules = [
        {
          rulePriority = 1
          description  = "Keep only last 10 images"
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
    ```

    Example — expire images older than 30 days:

    ```hcl
    lifecycle_policy = {
      rules = [
        {
          rulePriority = 1
          description  = "Expire images older than 30 days"
          selection = {
            tagStatus   = "any"
            countType   = "sinceImagePushed"
            countUnit   = "days"
            countNumber = 30
          }
          action = {
            type = "expire"
          }
        }
      ]
    }
    ```

    Leave null to skip lifecycle policy creation.
  EOT
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
  default = null
}

# -----------------------------------------------------------------------------
# Repository policy
# -----------------------------------------------------------------------------

variable "repository_policy" {
  description = <<-EOT
    IAM policy document for the repository.

    Controls who can access the repository. By default, no repository policy
    is set — access is controlled via IAM user/role permissions.

    Example — allow an IAM role to pull images:

    ```hcl
    repository_policy = {
      Version = "2012-10-17"
      Statement = [
        {
          Sid    = "AllowPull"
          Effect = "Allow"
          Principal = {
            AWS = "arn:aws:iam::123456789012:role/my-app-role"
          }
          Action = [
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage",
            "ecr:BatchCheckLayerAvailability"
          ]
          Resource = "*"
        }
      ]
    }
    ```

    Leave null to skip repository policy creation.
  EOT
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

# -----------------------------------------------------------------------------
# Tags
# -----------------------------------------------------------------------------

variable "tags" {
  description = "Additional tags to apply to the repository."
  type        = map(string)
  default     = {}
}
