# outputs.tf — values other modules or root configurations can read

output "repository_id" {
  description = "ID of the ECR repository."
  value       = aws_ecr_repository.this.id
}

output "repository_arn" {
  description = "ARN of the ECR repository."
  value       = aws_ecr_repository.this.arn
}

output "repository_url" {
  description = "URL of the ECR repository (used for docker push/pull)."
  value       = aws_ecr_repository.this.repository_url
}

output "repository_name" {
  description = "Name of the ECR repository."
  value       = aws_ecr_repository.this.name
}

output "registry_id" {
  description = "AWS account ID of the registry."
  value       = aws_ecr_repository.this.registry_id
}

output "repository_uri" {
  description = "URI of the ECR repository."
  value       = aws_ecr_repository.this.repository_url
}
