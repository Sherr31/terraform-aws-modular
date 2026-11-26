# examples/autoscaling/variables.tf

variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short project name used in default provider tags."
  type        = string
  default     = "asg-example"
}

variable "environment" {
  description = "Environment label."
  type        = string
  default     = "dev"
}

variable "name_prefix" {
  description = "Prefix used in ASG resource names."
  type        = string
  default     = "asg-example"
}

# -----------------------------------------------------------------------------
# AMI and instance
# -----------------------------------------------------------------------------

variable "ami" {
  description = "AMI ID for instances."
  type        = string
  default     = "ami-0c55b159cbfafe1f0"
}

variable "instance_type" {
  description = "Instance type."
  type        = string
  default     = "t3.micro"
}

# -----------------------------------------------------------------------------
# Network
# -----------------------------------------------------------------------------

variable "subnet_ids" {
  description = "List of subnet IDs for the ASG. Must have at least 2 subnets in different AZs for multi-AZ ASGs."
  type        = list(string)
  default     = []
}

variable "security_group_ids" {
  description = "List of security group IDs for instances."
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Sizing
# -----------------------------------------------------------------------------

variable "min_size" {
  description = "Minimum number of instances."
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of instances."
  type        = number
  default     = 3
}

variable "desired_capacity" {
  description = "Desired number of instances."
  type        = number
  default     = 1
}

# -----------------------------------------------------------------------------
# Health checks
# -----------------------------------------------------------------------------

variable "health_check_type" {
  description = "Health check type: EC2 or ELB."
  type        = string
  default     = "EC2"
}

variable "health_check_grace_period" {
  description = "Grace period in seconds before health checks start."
  type        = number
  default     = 300
}

# -----------------------------------------------------------------------------
# Target groups
# -----------------------------------------------------------------------------

variable "target_group_arns" {
  description = "List of target group ARNs to attach."
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Storage
# -----------------------------------------------------------------------------

variable "root_volume_size" {
  description = "Root volume size in GiB."
  type        = number
  default     = 10
}

variable "root_volume_type" {
  description = "Root volume type."
  type        = string
  default     = "gp3"
}

variable "root_volume_encrypted" {
  description = "Encrypt root volume."
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Metadata and monitoring
# -----------------------------------------------------------------------------

variable "imdsv2_required" {
  description = "Require IMDSv2."
  type        = bool
  default     = true
}

variable "enhanced_monitoring" {
  description = "Enable detailed monitoring."
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# User data and keys
# -----------------------------------------------------------------------------

variable "user_data" {
  description = "User data script. Optional."
  type        = string
  default     = null
}

variable "key_name" {
  description = "Key pair name. Optional."
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# Tags
# -----------------------------------------------------------------------------

variable "tags" {
  description = "Additional tags."
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# Termination
# -----------------------------------------------------------------------------

variable "termination_policies" {
  description = "Termination policies for the ASG."
  type        = list(string)
  default     = ["Default"]
}
