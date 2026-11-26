# apps/infrastructure-lab/outputs.tf

output "vpc_id" {
  description = "ID of the VPC."
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets."
  value       = module.vpc.private_subnet_ids
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer. Use this to access the application."
  value       = module.alb.alb_dns_name
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer."
  value       = module.alb.alb_arn
}

output "target_group_arn" {
  description = "ARN of the target group."
  value       = module.alb.target_group_arn
}

output "asg_name" {
  description = "Name of the Auto Scaling group."
  value       = module.asg.asg_name
}

output "asg_arn" {
  description = "ARN of the Auto Scaling group."
  value       = module.asg.asg_arn
}

output "app_security_group_id" {
  description = "ID of the application security group."
  value       = module.app_security_group.security_group_id
}

output "alb_security_group_id" {
  description = "ID of the ALB security group."
  value       = module.alb.security_group_id
}

output "launch_template_id" {
  description = "ID of the launch template."
  value       = module.asg.launch_template_id
}
