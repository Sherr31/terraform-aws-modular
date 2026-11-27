
output "vpc_id" {
  description = "Application VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "ec2_instance_id" {
  description = "Web server EC2 instance ID"
  value       = module.ec2.instance_id
}

output "ec2_public_ip" {
  description = "Web server public IP"
  value       = module.ec2.public_ip
}

output "alb_dns_name" {
  description = "Application Load Balancer DNS name"
  value       = module.alb.alb_dns_name
}

output "s3_bucket_name" {
  description = "Application S3 bucket name"
  value       = module.s3.bucket_id
}

output "ecr_repository_url" {
  description = "ECR Docker repository URL"
  value       = module.ecr.repository_url
}
