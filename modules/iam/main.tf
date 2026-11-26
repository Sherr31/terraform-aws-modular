# main.tf — reusable IAM role and policy module

# -----------------------------------------------------------------------------
# IAM Role — the identity that services assume to get permissions
# -----------------------------------------------------------------------------

resource "aws_iam_role" "this" {
  name                 = var.role_name
  assume_role_policy   = var.assume_role_policy
  max_session_duration = var.max_session_duration

  tags = merge(
    var.tags,
    {
      Name = var.role_name
    }
  )
}

# -----------------------------------------------------------------------------
# IAM Policy — the permissions document attached to the role
# -----------------------------------------------------------------------------

resource "aws_iam_policy" "this" {
  count = var.create_policy ? 1 : 0

  name        = var.policy_name != null ? var.policy_name : "${var.role_name}-policy"
  description = var.policy_description
  policy      = var.create_policy ? var.policy_document : null
  path        = var.policy_path

  tags = merge(
    var.tags,
    {
      Name = var.role_name
    }
  )
}

# -----------------------------------------------------------------------------
# Attach policy to role — links the permissions to the identity
# -----------------------------------------------------------------------------

resource "aws_iam_role_policy_attachment" "this" {
  count = var.create_policy ? 1 : 0

  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this[0].arn
}

# -----------------------------------------------------------------------------
# Instance profile — for EC2 instances to assume the role
# -----------------------------------------------------------------------------

resource "aws_iam_instance_profile" "this" {
  count = var.create_instance_profile ? 1 : 0

  name = var.instance_profile_name != null ? var.instance_profile_name : "${var.role_name}-profile"
  role = aws_iam_role.this.name
  path = var.instance_profile_path

  tags = merge(
    var.tags,
    {
      Name = var.role_name
    }
  )
}
