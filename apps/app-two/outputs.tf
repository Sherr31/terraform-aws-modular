
output "vpc_id" {
  description = "Shared VPC ID (app-one VPC)"
  value       = data.aws_vpc.app_one_vpc.id
}

output "alb_dns_name" {
  description = "Shared ALB DNS name"
  value       = data.aws_lb.app_one_alb.dns_name
}

output "autoscaling_group_name" {
  description = "Auto Scaling Group name"
  value       = module.autoscale.autoscaling_group_name
}

output "rds_endpoint" {
  description = "PostgreSQL database endpoint"
  value       = module.rds.db_endpoint
}

output "rds_address" {
  description = "RDS hostname"
  value       = module.rds.db_address
}

output "rds_port" {
  description = "RDS port"
  value       = module.rds.db_port
}

output "rds_db_name" {
  description = "Database name"
  value       = module.rds.db_name
}

output "rds_secret_arn" {
  description = "Secrets Manager ARN for RDS credentials"
  value       = module.rds.master_user_secret_arn
}

output "s3_bucket_name" {
  description = "S3 bucket name"
  value       = module.s3.bucket_id
}

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = module.ecr.repository_url
}

output "target_group_arn" {
  description = "App-two target group ARN"
  value       = aws_lb_target_group.app_two.arn
}
