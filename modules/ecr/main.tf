# main.tf — reusable ECR repository module

# -----------------------------------------------------------------------------
# ECR Repository — container image registry
# -----------------------------------------------------------------------------

resource "aws_ecr_repository" "this" {
  name                 = var.repository_name
  image_tag_mutability = var.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  encryption_configuration {
    encryption_type = var.encryption_type
    kms_key         = var.encryption_type == "aws:kms" ? var.kms_key_id : null
  }

  tags = merge(
    var.tags,
    {
      Name = var.repository_name
    }
  )
}

# -----------------------------------------------------------------------------
# Lifecycle policy — manage image cleanup automatically
# -----------------------------------------------------------------------------

resource "aws_ecr_lifecycle_policy" "this" {
  count = var.lifecycle_policy != null ? 1 : 0

  repository = aws_ecr_repository.this.name

  policy = jsonencode(var.lifecycle_policy)
}

# -----------------------------------------------------------------------------
# Repository policy — control access to the repository
# -----------------------------------------------------------------------------

resource "aws_ecr_repository_policy" "this" {
  count = var.repository_policy != null ? 1 : 0

  repository = aws_ecr_repository.this.name

  policy = jsonencode(var.repository_policy)
}
