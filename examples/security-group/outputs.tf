# examples/security-group/outputs.tf

output "security_group_id" {
  description = "ID of the security group created by the example."
  value       = module.web_security_group.security_group_id
}

output "security_group_arn" {
  description = "ARN of the security group."
  value       = module.web_security_group.security_group_arn
}
