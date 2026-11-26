# examples/iam/variables.tf

variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short project name used in default provider tags."
  type        = string
  default     = "iam-example"
}

variable "environment" {
  description = "Environment label."
  type        = string
  default     = "dev"
}

variable "role_name" {
  description = "Name of the IAM role."
  type        = string
  default     = "example-role"
}

variable "role_purpose" {
  description = "Purpose label for the role (used in tags)."
  type        = string
  default     = "example"
}

# -----------------------------------------------------------------------------
# Assume role policy
# -----------------------------------------------------------------------------

variable "assume_role_service" {
  description = "AWS service principal that can assume this role (e.g. ec2.amazonaws.com)."
  type        = string
  default     = "ec2.amazonaws.com"
}

# -----------------------------------------------------------------------------
# Policy
# -----------------------------------------------------------------------------

variable "create_policy" {
  description = "Whether to create and attach an IAM policy to the role."
  type        = bool
  default     = true
}

variable "policy_name" {
  description = "Name of the IAM policy. Defaults to role_name with '-policy' suffix."
  type        = string
  default     = null
}

variable "policy_description" {
  description = "Description of the IAM policy."
  type        = string
  default     = "Example policy for the IAM example role."
}

variable "policy_statements" {
  description = <<-EOT
    List of policy statements for the IAM policy.

    Each statement is a map with Effect, Action, Resource, and optional
    Sid, Condition, etc. This is passed into jsonencode() in main.tf.

    Example for S3 read-only access to a specific bucket:

    ```hcl
    policy_statements = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::my-bucket",
          "arn:aws:s3:::my-bucket/*"
        ]
      }
    ]
    ```
  EOT
  type        = list(any)
  default = [
    {
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket"
      ]
      Resource = "*"
    }
  ]
}

# -----------------------------------------------------------------------------
# Instance profile
# -----------------------------------------------------------------------------

variable "create_instance_profile" {
  description = "Whether to create an IAM instance profile for EC2."
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Session duration
# -----------------------------------------------------------------------------

variable "max_session_duration" {
  description = "Maximum session duration in seconds (3600 to 43200)."
  type        = number
  default     = 3600
}

# -----------------------------------------------------------------------------
# Tags
# -----------------------------------------------------------------------------

variable "tags" {
  description = "Additional tags to apply to the role and policy."
  type        = map(string)
  default     = {}
}
