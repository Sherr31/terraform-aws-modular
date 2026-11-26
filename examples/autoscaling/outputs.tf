# examples/autoscaling/outputs.tf

output "asg_name" {
  description = "Name of the Auto Scaling group created by the example."
  value       = module.asg.asg_name
}

output "asg_arn" {
  description = "ARN of the Auto Scaling group."
  value       = module.asg.asg_arn
}

output "launch_template_id" {
  description = "ID of the launch template."
  value       = module.asg.launch_template_id
}
