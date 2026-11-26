# examples/iam/outputs.tf

output "role_name" {
  description = "Name of the IAM role created by the example."
  value       = module.iam_role.role_name
}

output "role_arn" {
  description = "ARN of the IAM role."
  value       = module.iam_role.role_arn
}

output "role_unique_id" {
  description = "Stable unique ID of the IAM role."
  value       = module.iam_role.role_unique_id
}

output "policy_arn" {
  description = "ARN of the IAM policy, if created."
  value       = module.iam_role.policy_arn
}

output "instance_profile_name" {
  description = "Name of the instance profile, if created."
  value       = module.iam_role.instance_profile_name
}

output "instance_profile_arn" {
  description = "ARN of the instance profile, if created."
  value       = module.iam_role.instance_profile_arn
}
