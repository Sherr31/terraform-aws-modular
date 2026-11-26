# examples/s3/variables.tf

variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short project name used in default provider tags."
  type        = string
  default     = "s3-example"
}

variable "environment" {
  description = "Environment label."
  type        = string
  default     = "dev"
}

variable "bucket_name" {
  description = <<-EOT
    Name of the S3 bucket. Must be globally unique across all of AWS.

    The default uses a placeholder. Replace it with a unique name before
    applying — include your project, environment, and ideally an account
    ID or random suffix.
  EOT
  type        = string
  default     = "s3-example-bucket-replace-me"
}

variable "bucket_purpose" {
  description = "Purpose label for the bucket (used in tags)."
  type        = string
  default     = "example"
}

variable "versioning_enabled" {
  description = "Enable S3 bucket versioning."
  type        = bool
  default     = false
}

variable "sse_algorithm" {
  description = "Server-side encryption algorithm: AES256 or aws:kms."
  type        = string
  default     = "AES256"
}

variable "kms_key_id" {
  description = "KMS key ID for aws:kms encryption. Ignored for AES256."
  type        = string
  default     = null
}

variable "object_ownership" {
  description = "Object ownership setting: BucketOwnerEnforced, BucketOwnerPreferred, or ObjectWriter."
  type        = string
  default     = "BucketOwnerEnforced"
}

variable "acl" {
  description = "Canned ACL for the bucket. Ignored when object_ownership is BucketOwnerEnforced."
  type        = string
  default     = null
}

variable "lifecycle_rules" {
  description = "Lifecycle rules for the bucket."
  type = list(object({
    id     = string
    status = string
    transitions = optional(list(object({
      days          = number
      storage_class = string
    })))
    expiration = optional(object({
      days = number
    }))
    noncurrent_version_transitions = optional(list(object({
      noncurrent_days = number
      storage_class   = string
    })))
    noncurrent_version_expiration = optional(object({
      noncurrent_days = number
    }))
  }))
  default = []
}

variable "tags" {
  description = "Additional tags to apply to the bucket."
  type        = map(string)
  default     = {}
}
