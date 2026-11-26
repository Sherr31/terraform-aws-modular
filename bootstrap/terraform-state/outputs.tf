# bootstrap/terraform-state/outputs.tf

output "bucket_name" {
  description = "Name of the Terraform state S3 bucket."
  value       = aws_s3_bucket.terraform_state.bucket
}

output "bucket_arn" {
  description = "ARN of the Terraform state S3 bucket."
  value       = aws_s3_bucket.terraform_state.arn
}

output "bucket_region" {
  description = "Region of the Terraform state S3 bucket."
  value       = aws_s3_bucket.terraform_state.region
}

output "lock_table_name" {
  description = "Name of the DynamoDB table for state locking."
  value       = aws_dynamodb_table.terraform_locks.name
}

output "lock_table_arn" {
  description = "ARN of the DynamoDB table for state locking."
  value       = aws_dynamodb_table.terraform_locks.arn
}

output "access_policy_arn" {
  description = "ARN of the IAM policy for Terraform state access."
  value       = var.create_access_policy ? aws_iam_policy.terraform_state_access[0].arn : null
}
