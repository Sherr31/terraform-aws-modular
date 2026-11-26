# outputs.tf — values other modules or root configurations can read

output "asg_name" {
  description = "Name of the Auto Scaling group."
  value       = aws_autoscaling_group.this.name
}

output "asg_arn" {
  description = "ARN of the Auto Scaling group."
  value       = aws_autoscaling_group.this.arn
}

output "launch_template_id" {
  description = "ID of the launch template."
  value       = aws_launch_template.this.id
}

output "launch_template_arn" {
  description = "ARN of the launch template."
  value       = aws_launch_template.this.arn
}

output "iam_instance_profile_name" {
  description = "Name of the IAM instance profile, if created."
  value       = var.create_iam_instance_profile ? aws_iam_instance_profile.this[0].name : var.instance_profile_name
}
