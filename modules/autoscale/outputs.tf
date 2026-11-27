output "launch_template_id" {
  description = "ID of the launch template"
  value       = aws_launch_template.this.id
}

output "launch_template_arn" {
  description = "ARN of the launch template"
  value       = aws_launch_template.this.arn
}

output "launch_template_name" {
  description = "Name of the launch template"
  value       = aws_launch_template.this.name
}

output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.this.name
}

output "autoscaling_group_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = aws_autoscaling_group.this.arn
}

output "autoscaling_group_min_size" {
  description = "Minimum size of the Auto Scaling Group"
  value       = aws_autoscaling_group.this.min_size
}

output "autoscaling_group_max_size" {
  description = "Maximum size of the Auto Scaling Group"
  value       = aws_autoscaling_group.this.max_size
}

output "autoscaling_group_desired_capacity" {
  description = "Desired capacity of the Auto Scaling Group"
  value       = aws_autoscaling_group.this.desired_capacity
}

output "iam_role_name" {
  description = "Name of the EC2 instance IAM role"
  value       = aws_iam_role.this.name
}

output "iam_role_arn" {
  description = "ARN of the EC2 instance IAM role"
  value       = aws_iam_role.this.arn
}

output "instance_profile_name" {
  description = "Name of the IAM instance profile"
  value       = aws_iam_instance_profile.this.name
}

output "ami_id" {
  description = "AMI ID used by the launch template"
  value       = aws_launch_template.this.image_id
}
