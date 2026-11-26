# outputs.tf — values other modules or root configurations can read

output "alb_arn" {
  description = "ARN of the Application Load Balancer."
  value       = aws_lb.this.arn
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer."
  value       = aws_lb.this.dns_name
}

output "alb_zone_id" {
  description = "Route 53 zone ID for creating ALIAS records pointing to this ALB."
  value       = aws_lb.this.zone_id
}

output "alb_id" {
  description = "ID of the Application Load Balancer."
  value       = aws_lb.this.id
}

output "security_group_id" {
  description = "ID of the security group used by the ALB."
  value       = var.security_group_id != null ? var.security_group_id : var.create_security_group ? aws_security_group.alb[0].id : null
}

output "target_group_arn" {
  description = "ARN of the default target group."
  value       = aws_lb_target_group.this.arn
}

output "target_group_name" {
  description = "Name of the default target group."
  value       = aws_lb_target_group.this.name
}

output "listener_arn" {
  description = "ARN of the default HTTP listener."
  value       = aws_lb_listener.http.arn
}
