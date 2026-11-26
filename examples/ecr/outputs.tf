# examples/ecr/outputs.tf

output "repository_id" {
  description = "ID of the ECR repository created by the example."
  value       = module.ecr.repository_id
}

output "repository_arn" {
  description = "ARN of the ECR repository."
  value       = module.ecr.repository_arn
}

output "repository_url" {
  description = "URL of the ECR repository (for docker push/pull)."
  value       = module.ecr.repository_url
}

output "repository_name" {
  description = "Name of the ECR repository."
  value       = module.ecr.repository_name
}

output "registry_id" {
  description = "AWS account ID of the registry."
  value       = module.ecr.registry_id
}
