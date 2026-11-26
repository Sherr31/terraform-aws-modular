# outputs.tf — values other modules or root configurations can read

output "security_group_id" {
  description = "ID of the security group."
  value       = aws_security_group.this.id
}

output "security_group_arn" {
  description = "ARN of the security group."
  value       = aws_security_group.this.arn
}

output "security_group_name" {
  description = "Name of the security group."
  value       = aws_security_group.this.name
}

output "vpc_id" {
  description = "ID of the VPC where the security group was created."
  value       = aws_security_group.this.vpc_id
}
