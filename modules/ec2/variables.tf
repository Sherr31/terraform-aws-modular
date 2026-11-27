
variable "name" {
  description = "Name of the EC2 instance"
  type        = string

  validation {
    condition     = length(trimspace(var.name)) > 0
    error_message = "Instance name cannot be empty."
  }
}

variable "ami_id" {
  description = "AMI ID used to launch the EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "subnet_id" {
  description = "Subnet ID where the instance will be launched"
  type        = string
}

variable "security_group_ids" {
  description = "List of security group IDs"
  type        = list(string)

  validation {
    condition     = length(var.security_group_ids) > 0
    error_message = "At least one security group ID must be provided."
  }
}

variable "key_name" {
  description = "AWS EC2 SSH key pair name"
  type        = string
  default     = "aws-secure-vpc"
}

variable "iam_instance_profile" {
  description = "Optional IAM instance profile name"
  type        = string
  default     = null
}

variable "associate_public_ip_address" {
  description = "Whether to associate a public IP address"
  type        = bool
  default     = false
}

variable "root_volume_size" {
  description = "Root EBS volume size in GiB"
  type        = number
  default     = 20

  validation {
    condition     = var.root_volume_size >= 8
    error_message = "Root volume size must be at least 8 GiB."
  }
}

variable "root_volume_type" {
  description = "Root EBS volume type"
  type        = string
  default     = "gp3"
}

variable "root_volume_encrypted" {
  description = "Enable encryption for the root EBS volume"
  type        = bool
  default     = true
}

variable "monitoring" {
  description = "Enable detailed EC2 monitoring"
  type        = bool
  default     = false
}

variable "user_data" {
  description = "Optional startup script for the instance"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to the EC2 instance"
  type        = map(string)
  default     = {}
}
