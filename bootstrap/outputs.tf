
output "state_bucket_name" {
  description = "Terraform remote state S3 bucket"
  value       = aws_s3_bucket.terraform_state.id
}

output "state_bucket_arn" {
  description = "Terraform remote state S3 bucket ARN"
  value       = aws_s3_bucket.terraform_state.arn
}

output "github_oidc_provider_arn" {
  description = "Existing GitHub Actions OIDC provider ARN"
  value       = data.aws_iam_openid_connect_provider.github.arn
}

output "github_actions_role_arn" {
  description = "Existing GitHub Actions IAM role ARN"
  value       = data.aws_iam_role.github_actions.arn
}

output "aws_account_id" {
  description = "AWS account ID"
  value       = data.aws_caller_identity.current.account_id
}
