# examples/alb/outputs.tf

output "alb_arn" {
  description = "ARN of the ALB created by the example."
  value       = module.alb.alb_arn
}

output "alb_dns_name" {
  description = "DNS name of the ALB."
  value       = module.alb.alb_dns_name
}

output "alb_zone_id" {
  description = "Route 53 zone ID for ALIAS records."
  value       = module.alb.alb_zone_id
}

output "target_group_arn" {
  description = "ARN of the default target group."
  value       = module.alb.target_group_arn
}

output "security_group_id" {
  description = "Security group ID used by the ALB."
  value       = module.alb.security_group_id
}
