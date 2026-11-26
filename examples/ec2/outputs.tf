# examples/ec2/outputs.tf

# The EC2 module exposes many values. This root configuration exposes the ones
# most likely to matter first.

output "instance_id" {
  description = "ID of the EC2 instance created by the example."
  value       = module.ec2.instance_id
}

output "arn" {
  description = "ARN of the EC2 instance."
  value       = module.ec2.arn
}

output "public_ip" {
  description = "Public IP address, if one was assigned."
  value       = module.ec2.public_ip
}

output "private_ip" {
  description = "Private IP address of the instance."
  value       = module.ec2.private_ip
}

output "public_dns" {
  description = "Public DNS name, if available."
  value       = module.ec2.public_dns
}

output "availability_zone" {
  description = "Availability Zone of the instance."
  value       = module.ec2.availability_zone
}

output "security_group_id" {
  description = "Security group ID attached to the example instance."
  value       = aws_security_group.example.id
}
