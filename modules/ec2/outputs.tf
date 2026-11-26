# outputs.tf — values other modules or root configurations can read

output "instance_id" {
  description = "ID of the EC2 instance."
  value       = aws_instance.this.id
}

output "arn" {
  description = "ARN of the EC2 instance."
  value       = aws_instance.this.arn
}

output "public_ip" {
  description = "Public IP address, if one was assigned."
  value       = aws_instance.this.public_ip
}

output "private_ip" {
  description = "Private IP address of the instance."
  value       = aws_instance.this.private_ip
}

output "public_dns" {
  description = "Public DNS name, if available."
  value       = aws_instance.this.public_dns
}

output "availability_zone" {
  description = "Availability Zone of the instance."
  value       = aws_instance.this.availability_zone
}

output "primary_network_interface_id" {
  description = "ID of the instance's primary network interface."
  value       = aws_instance.this.primary_network_interface_id
}

