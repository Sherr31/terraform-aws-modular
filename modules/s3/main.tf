# main.tf — reusable S3 bucket module

# -----------------------------------------------------------------------------
# S3 Bucket — the core storage resource
# -----------------------------------------------------------------------------

resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name

  tags = merge(
    var.tags,
    {
      Name = var.bucket_name
    }
  )
}

# -----------------------------------------------------------------------------
# Versioning — optional, keeps history of object changes
# -----------------------------------------------------------------------------

resource "aws_s3_bucket_versioning" "this" {
  count = var.versioning_enabled ? 1 : 0

  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = var.versioning_enabled ? "Enabled" : "Disabled"
  }
}

# -----------------------------------------------------------------------------
# Server-side encryption — always enabled by default for security
# -----------------------------------------------------------------------------

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = var.sse_algorithm
      # KMS key ID only used when sse_algorithm is "aws:kms"
      kms_master_key_id = var.sse_algorithm == "aws:kms" ? var.kms_key_id : null
    }
  }
}

# -----------------------------------------------------------------------------
# Public access block — blocks all public access by default
# -----------------------------------------------------------------------------

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = var.block_public_acls
  block_public_policy     = var.block_public_policy
  ignore_public_acls      = var.ignore_public_acls
  restrict_public_buckets = var.restrict_public_buckets
}

# -----------------------------------------------------------------------------
# ACL — controls object ownership and access model
# -----------------------------------------------------------------------------

resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    object_ownership = var.object_ownership
  }
}

resource "aws_s3_bucket_acl" "this" {
  count = var.acl != null ? 1 : 0

  bucket = aws_s3_bucket.this.id
  acl    = var.acl
}

# -----------------------------------------------------------------------------
# Lifecycle rules — optional, for cost control on versioned/expiring data
# -----------------------------------------------------------------------------

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count = length(var.lifecycle_rules) > 0 ? 1 : 0

  bucket = aws_s3_bucket.this.id

  dynamic "rule" {
    for_each = var.lifecycle_rules
    content {
      id     = rule.value.id
      status = rule.value.status

      # Transition rules — move objects to cheaper storage classes over time
      dynamic "transition" {
        for_each = lookup(rule.value, "transitions", []) != [] ? rule.value.transitions : []
        content {
          days          = transition.value.days
          storage_class = transition.value.storage_class
        }
      }

      # Expiration — delete objects after a period
      dynamic "expiration" {
        for_each = lookup(rule.value, "expiration", {}) != {} ? [rule.value.expiration] : []
        content {
          days = expiration.value.days
        }
      }

      # Noncurrent version transition — for versioned buckets
      dynamic "noncurrent_version_transition" {
        for_each = lookup(rule.value, "noncurrent_version_transitions", []) != [] ? rule.value.noncurrent_version_transitions : []
        content {
          noncurrent_days = noncurrent_version_transition.value.noncurrent_days
          storage_class   = noncurrent_version_transition.value.storage_class
        }
      }

      # Noncurrent version expiration — for versioned buckets
      dynamic "noncurrent_version_expiration" {
        for_each = lookup(rule.value, "noncurrent_version_expiration", {}) != {} ? [rule.value.noncurrent_version_expiration] : []
        content {
          noncurrent_days = noncurrent_version_expiration.value.noncurrent_days
        }
      }
    }
  }
}
