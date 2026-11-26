# variables.tf — inputs for the reusable Auto Scaling module

# -----------------------------------------------------------------------------
# Naming
# -----------------------------------------------------------------------------

variable "name_prefix" {
  description = "Prefix used in ASG, launch template, and instance profile names."
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags to apply to the ASG and launch template."
  type        = map(string)
  default     = {}
}

variable "extra_tags" {
  description = "Extra tags to propagate to instances from the ASG."
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# Network
# -----------------------------------------------------------------------------

variable "subnet_ids" {
  description = "List of subnet IDs for the ASG. Instances are distributed across these subnets."
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs to attach to instances."
  type        = list(string)
  default     = []
}

variable "associate_public_ip" {
  description = "Whether to assign public IPs to instances. Use false for private subnets."
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# AMI and instance type
# -----------------------------------------------------------------------------

variable "ami" {
  description = "AMI ID for instances in the ASG."
  type        = string
}

variable "instance_type" {
  description = "Instance type for instances in the ASG."
  type        = string
  default     = "t3.micro"
}

# -----------------------------------------------------------------------------
# IAM
# -----------------------------------------------------------------------------

variable "create_iam_instance_profile" {
  description = "Whether to create an IAM instance profile for instances."
  type        = bool
  default     = false
}

variable "iam_role_name" {
  description = "Name of the IAM role to attach to the instance profile."
  type        = string
  default     = null
}

variable "iam_instance_profile_arn" {
  description = "ARN of an existing IAM instance profile to use instead of creating one."
  type        = string
  default     = null
}

variable "instance_profile_name" {
  description = "Name of an existing instance profile to use. Overrides create_iam_instance_profile."
  type        = string
  default     = null
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
  description = "Root volume type: gp2, gp3, io1, io2, sc1, st1."
  type        = string
  default     = "gp3"
}

variable "root_volume_encrypted" {
  description = "Encrypt the root volume."
  type        = bool
  default     = true
}

variable "root_delete_on_termination" {
  description = "Delete root volume on instance termination."
  type        = bool
  default     = true
}

variable "root_volume_iops" {
  description = "IOPS for provisioned IOPS volumes (io1, io2). Ignored for gp2/gp3."
  type        = number
  default     = null
}

variable "root_volume_throughput" {
  description = "Throughput in MiB/s for gp3 volumes. Ignored for other types."
  type        = number
  default     = null
}

# -----------------------------------------------------------------------------
# Metadata / IMDS
# -----------------------------------------------------------------------------

variable "imdsv2_required" {
  description = "Require IMDSv2 session tokens."
  type        = bool
  default     = true
}

variable "http_put_response_hop_limit" {
  description = "Number of hops for IMDSv2 PUT responses. Range: 1-64."
  type        = number
  default     = 1
}

# -----------------------------------------------------------------------------
# User data and key pair
# -----------------------------------------------------------------------------

variable "user_data" {
  description = "User data script to run on instance launch. Optional."
  type        = string
  default     = null
}

variable "key_name" {
  description = "Name of an existing EC2 key pair. Optional."
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# Monitoring
# -----------------------------------------------------------------------------

variable "enhanced_monitoring" {
  description = "Enable detailed monitoring (1-minute periods) on instances."
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# ASG sizing
# -----------------------------------------------------------------------------

variable "min_size" {
  description = "Minimum number of instances in the ASG."
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of instances in the ASG."
  type        = number
  default     = 3
}

variable "desired_capacity" {
  description = "Desired number of instances in the ASG."
  type        = number
  default     = 1
}

# -----------------------------------------------------------------------------
# Health checks
# -----------------------------------------------------------------------------

variable "health_check_type" {
  description = "Health check type: EC2 or ELB. ELB uses target group health checks."
  type        = string
  default     = "EC2"

  validation {
    condition     = contains(["EC2", "ELB", "None"], var.health_check_type)
    error_message = "health_check_type must be 'EC2', 'ELB', or 'None'."
  }
}

variable "health_check_grace_period" {
  description = "Time in seconds after instance launch before health checks start."
  type        = number
  default     = 300
}

# -----------------------------------------------------------------------------
# Target groups
# -----------------------------------------------------------------------------

variable "target_group_arns" {
  description = "List of target group ARNs to attach to the ASG."
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Instance refresh
# -----------------------------------------------------------------------------

variable "instance_refresh_strategy" {
  description = "Strategy for instance refresh: Rolling, Panic, etc."
  type        = string
  default     = "Rolling"

  validation {
    condition     = contains(["Rolling", "Panic"], var.instance_refresh_strategy)
    error_message = "instance_refresh_strategy must be 'Rolling' or 'Panic'."
  }
}

variable "instance_refresh_min_healthy_percentage" {
  description = "Minimum healthy percentage during instance refresh."
  type        = number
  default     = 50
}

variable "instance_refresh_auto_rollback" {
  description = "Roll back if health checks fail during refresh."
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Instance protection
# -----------------------------------------------------------------------------

variable "new_instance_protection" {
  description = "Protect new instances from scale-in."
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Termination policies
# -----------------------------------------------------------------------------

variable "termination_policies" {
  description = "Termination policies for the ASG."
  type        = list(string)
  default     = ["Default"]
}

# -----------------------------------------------------------------------------
# Capacity management
# -----------------------------------------------------------------------------

variable "wait_for_capacity_timeout" {
  description = "Time to wait for capacity before giving up. Set to 0 to skip."
  type        = string
  default     = "10m"
}

variable "skip_wait_for_monthly_capacity_timeout" {
  description = "Skip waiting for monthly capacity timeout."
  type        = bool
  default     = false
}

variable "capacity_rebalance" {
  description = "Enable capacity rebalance for Spot instances."
  type        = bool
  default     = false
}

variable "ignore_process_termination_backoff" {
  description = "Back off when processes are terminated."
  type        = bool
  default     = false
}
