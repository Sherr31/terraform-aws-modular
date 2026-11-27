
output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.this.id
}

output "instance_arn" {
  description = "ARN of the EC2 instance"
  value       = aws_instance.this.arn
}

output "instance_type" {
  description = "Instance type"
  value       = aws_instance.this.instance_type
}

output "key_name" {
  description = "SSH key pair associated with the instance"
  value       = aws_instance.this.key_name
}

output "private_ip" {
  description = "Private IP address of the instance"
  value       = aws_instance.this.private_ip
}

output "public_ip" {
  description = "Public IP address, if assigned"
  value       = aws_instance.this.public_ip
}

output "public_dns" {
  description = "Public DNS name, if assigned"
  value       = aws_instance.this.public_dns
}

output "availability_zone" {
  description = "Availability zone of the instance"
  value       = aws_instance.this.availability_zone
}
