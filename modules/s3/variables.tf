# variables.tf — inputs for the reusable S3 bucket module

# -----------------------------------------------------------------------------
# Bucket name
# -----------------------------------------------------------------------------

variable "bucket_name" {
  description = <<-EOT
    Name of the S3 bucket.

    Bucket names must be globally unique across all of AWS and follow DNS
    naming rules: lowercase, no spaces, can include hyphens and dots.

    For unique names in reusable code, pass in a name that includes your
    project, environment, and a random or account-specific suffix. For
    example: "myapp-dev-logs-123456789012".
  EOT
  type        = string
}

# -----------------------------------------------------------------------------
# Tags
# -----------------------------------------------------------------------------

variable "tags" {
  description = "Additional tags to apply to the bucket."
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# Versioning
# -----------------------------------------------------------------------------

variable "versioning_enabled" {
  description = <<-EOT
    Enable bucket versioning.

    Versioning keeps multiple variants of an object, which protects against
    accidental deletion or overwrites. It also increases storage costs because
    older versions are retained.

    Disable for simple buckets where you do not need object history.
  EOT
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Server-side encryption
# -----------------------------------------------------------------------------

variable "sse_algorithm" {
  description = <<-EOT
    Server-side encryption algorithm to use.

    - "AES256" — S3-managed keys (default, no extra setup needed)
    - "aws:kms" — AWS KMS-managed keys (requires kms_key_id if you want a
      specific key; otherwise S3 uses its managed KMS key)
  EOT
  type        = string
  default     = "AES256"

  validation {
    condition     = contains(["AES256", "aws:kms"], var.sse_algorithm)
    error_message = "sse_algorithm must be either 'AES256' or 'aws:kms'."
  }
}

variable "kms_key_id" {
  description = <<-EOT
    KMS key ID to use for encryption when sse_algorithm is "aws:kms".

    Ignored when sse_algorithm is "AES256".

    Leave empty to use the S3-managed KMS key (aws/s3).
  EOT
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# Public access block
# -----------------------------------------------------------------------------

variable "block_public_acls" {
  description = "Block public ACLs on the bucket."
  type        = bool
  default     = true
}

variable "block_public_policy" {
  description = "Block public bucket policies."
  type        = bool
  default     = true
}

variable "ignore_public_acls" {
  description = "Ignore public ACLs on the bucket."
  type        = bool
  default     = true
}

variable "restrict_public_buckets" {
  description = "Restrict public bucket policies to AWS service principals."
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Object ownership and ACL
# -----------------------------------------------------------------------------

variable "object_ownership" {
  description = <<-EOT
    Object ownership control for the bucket.

    - "BucketOwnerEnforced" — disables ACLs, bucket owner owns all objects
      (recommended default for new buckets)
    - "BucketOwnerPreferred" — ACLs still work, but new objects are owned
      by the bucket owner
    - "ObjectWriter" — the uploading account owns the object
  EOT
  type        = string
  default     = "BucketOwnerEnforced"

  validation {
    condition     = contains(["BucketOwnerEnforced", "BucketOwnerPreferred", "ObjectWriter"], var.object_ownership)
    error_message = "object_ownership must be one of: BucketOwnerEnforced, BucketOwnerPreferred, ObjectWriter."
  }
}

variable "acl" {
  description = <<-EOT
    Canned ACL to apply to the bucket.

    Only used when object_ownership allows ACLs. With "BucketOwnerEnforced",
    ACLs are disabled and this setting is ignored.

    Leave null to skip setting an ACL entirely (recommended with
    BucketOwnerEnforced).
  EOT
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# Lifecycle rules
# -----------------------------------------------------------------------------

variable "lifecycle_rules" {
  description = <<-EOT
    List of lifecycle rules for the bucket.

    Use lifecycle rules to manage object storage costs over time. Common
    patterns include:

    - Transition objects to Infrequent Access or Glacier after a period
    - Expire (delete) objects after a retention period
    - Clean up old versions of objects in versioned buckets

    Example:

    ```hcl
    lifecycle_rules = [
      {
        id     = "move-to-ia"
        status = "Enabled"
        transitions = [
          {
            days          = 30
            storage_class = "STANDARD_IA"
          }
        ]
        noncurrent_version_transitions = [
          {
            noncurrent_days = 30
            storage_class   = "STANDARD_IA"
          }
        ]
      },
      {
        id     = "expire-old-objects"
        status = "Enabled"
        expiration = {
          days = 365
        }
      }
    ]
    ```
  EOT
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
