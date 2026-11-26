# variables.tf — inputs for the reusable IAM role and policy module

# -----------------------------------------------------------------------------
# Role name
# -----------------------------------------------------------------------------

variable "role_name" {
  description = <<-EOT
    Name of the IAM role.

    IAM role names are not globally unique like S3 bucket names, but they
    are unique within an AWS account. Pick a descriptive name that includes
    the service or purpose.
  EOT
  type        = string
}

# -----------------------------------------------------------------------------
# Assume role policy — who can assume this role
# -----------------------------------------------------------------------------

variable "assume_role_policy" {
  description = <<-EOT
    JSON policy document that defines who can assume this role.

    This is required. It is typically a JSON string with a Version and
    Statement block. For example, a role that EC2 instances assume:

    ```hcl
    assume_role_policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Principal = {
            Service = "ec2.amazonaws.com"
          }
        }
      ]
    })
    ```

    For a role that another AWS account assumes:

    ```hcl
    assume_role_policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Principal = {
            AWS = "arn:aws:iam::123456789012:root"
          }
        }
      ]
    })
    ```
  EOT
  type        = string
}

# -----------------------------------------------------------------------------
# Policy creation toggle
# -----------------------------------------------------------------------------

variable "create_policy" {
  description = <<-EOT
    Whether to create and attach an IAM policy to this role.

    When true, the module creates an IAM policy with the contents of
    var.policy_document and attaches it to the role.

    When false, the module only creates the role. You can attach existing
    policies or policies from other modules separately.
  EOT
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Policy document — the permissions
# -----------------------------------------------------------------------------

variable "policy_document" {
  description = <<-EOT
    JSON policy document that defines the permissions for this role.

    Required when create_policy is true. Use jsonencode() to build this
    from a Terraform expression, or pass a JSON string directly.

    Example:

    ```hcl
    policy_document = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "s3:GetObject",
            "s3:PutObject",
          ]
          Resource = "arn:aws:s3:::my-bucket/*"
        }
      ]
    })
    ```
  EOT
  type        = string
  default     = ""
}

variable "policy_name" {
  description = "Name of the IAM policy. Defaults to role_name with '-policy' suffix."
  type        = string
  default     = null
}

variable "policy_description" {
  description = "Description of the IAM policy."
  type        = string
  default     = "Policy for IAM role."
}

variable "policy_path" {
  description = "Path for the IAM policy. Defaults to /."
  type        = string
  default     = "/"
}

# -----------------------------------------------------------------------------
# Instance profile
# -----------------------------------------------------------------------------

variable "create_instance_profile" {
  description = <<-EOT
    Whether to create an IAM instance profile for this role.

    Instance profiles are required when EC2 instances need to assume this
    role. They act as a container for the role that EC2 can reference.

    Set to false if this role is for a different service (Lambda, ECS, etc.)
    or if you will create the instance profile separately.
  EOT
  type        = bool
  default     = false
}

variable "instance_profile_name" {
  description = "Name of the instance profile. Defaults to role_name with '-profile' suffix."
  type        = string
  default     = null
}

variable "instance_profile_path" {
  description = "Path for the instance profile. Defaults to /."
  type        = string
  default     = "/"
}

# -----------------------------------------------------------------------------
# Session duration
# -----------------------------------------------------------------------------

variable "max_session_duration" {
  description = <<-EOT
    Maximum session duration for the role in seconds.

    Allowed values: 3600 (1 hour) to 43200 (12 hours).

    Default is 3600 (1 hour), which is the AWS default for new roles.
  EOT
  type        = number
  default     = 3600

  validation {
    condition     = var.max_session_duration >= 3600 && var.max_session_duration <= 43200
    error_message = "max_session_duration must be between 3600 and 43200 seconds."
  }
}

# -----------------------------------------------------------------------------
# Tags
# -----------------------------------------------------------------------------

variable "tags" {
  description = "Additional tags to apply to all resources in this module."
  type        = map(string)
  default     = {}
}
