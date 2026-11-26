# outputs.tf — values other modules or root configurations can read

output "role_name" {
  description = "Name of the IAM role."
  value       = aws_iam_role.this.name
}

output "role_arn" {
  description = "ARN of the IAM role."
  value       = aws_iam_role.this.arn
}

output "role_unique_id" {
  description = "Stable unique ID of the IAM role."
  value       = aws_iam_role.this.unique_id
}

output "policy_arn" {
  description = "ARN of the IAM policy, if created. Empty if create_policy is false."
  value       = var.create_policy ? aws_iam_policy.this[0].arn : null
}

output "policy_id" {
  description = "ID of the IAM policy, if created. Empty if create_policy is false."
  value       = var.create_policy ? aws_iam_policy.this[0].id : null
}

output "instance_profile_name" {
  description = "Name of the instance profile, if created. Empty if create_instance_profile is false."
  value       = var.create_instance_profile ? aws_iam_instance_profile.this[0].name : null
}

output "instance_profile_arn" {
  description = "ARN of the instance profile, if created. Empty if create_instance_profile is false."
  value       = var.create_instance_profile ? aws_iam_instance_profile.this[0].arn : null
}
