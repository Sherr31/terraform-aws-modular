variable "name" {
  description = "Name prefix for Auto Scaling resources"
  type        = string

  validation {
    condition     = length(trimspace(var.name)) > 0
    error_message = "Name must not be empty."
  }
}

variable "ami_id" {
  description = "Optional AMI ID; defaults to latest Ubuntu 24.04"
  type        = string
  default     = null
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "subnet_ids" {
  description = "Subnet IDs for the Auto Scaling Group"
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "At least 2 subnet IDs are required."
  }
}

variable "security_group_ids" {
  description = "Security group IDs for EC2 instances"
  type        = list(string)

  validation {
    condition     = length(var.security_group_ids) > 0
    error_message = "At least one security group ID is required."
  }
}

variable "associate_public_ip_address" {
  description = "Assign public IP to instances"
  type        = bool
  default     = true
}

variable "instance_profile_name" {
  description = "IAM instance profile name; auto-created if not set"
  type        = string
  default     = null
}

variable "instance_role_name" {
  description = "IAM role name for EC2 instances; auto-created if not set"
  type        = string
  default     = null
}

variable "ecr_repository_arns" {
  description = "List of ECR repository ARNs for read-only access"
  type        = list(string)
  default     = []
}

variable "ecr_registry_id" {
  description = "AWS account ID for ECR registry"
  type        = string
}

variable "ecr_image_url" {
  description = "ECR image URL (registry/repository)"
  type        = string
}

variable "ecr_image_tag" {
  description = "Immutable ECR image tag (commit SHA)"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "user_data" {
  description = "Optional custom user_data script"
  type        = string
  default     = null
}

variable "root_volume_size" {
  description = "Root EBS volume size in GiB"
  type        = number
  default     = 20
}

variable "root_volume_type" {
  description = "Root EBS volume type"
  type        = string
  default     = "gp3"
}

variable "root_volume_encrypted" {
  description = "Encrypt root volume"
  type        = bool
  default     = true
}

variable "enhanced_monitoring" {
  description = "Enable detailed CloudWatch monitoring"
  type        = bool
  default     = true
}

variable "min_size" {
  description = "Minimum ASG capacity"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum ASG capacity"
  type        = number
  default     = 2
}

variable "desired_capacity" {
  description = "Desired ASG capacity"
  type        = number
  default     = 1
}

variable "target_group_arns" {
  description = "ALB target group ARNs to attach instances to"
  type        = list(string)
  default     = []
}

variable "cpu_alarm" {
  description = "Create CPU utilization alarm"
  type        = bool
  default     = true
}

variable "cpu_threshold" {
  description = "CPU threshold for scaling alarm"
  type        = number
  default     = 80
}

variable "alarm_actions" {
  description = "SNS topic ARNs or other actions for alarms"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}
