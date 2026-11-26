# variables.tf — inputs for the reusable EC2 instance module

# -----------------------------------------------------------------------------
# AMI
# -----------------------------------------------------------------------------

variable "ami" {
  description = <<-EOT
    AMI ID for the instance.

    This is a required input. Do not rely on a hardcoded default in reusable
    code; AMI IDs differ by region, account, and OS/image build.

    For repeatable, region-aware AMI selection in production, consider using
    a data source such as aws_ami in the root configuration and passing the
    resolved AMI ID into this module.
  EOT
  type        = string
}

# -----------------------------------------------------------------------------
# Instance type
# -----------------------------------------------------------------------------

variable "instance_type" {
  description = "Instance type, for example t3.micro."
  type        = string
  default     = "t3.micro"
}

# -----------------------------------------------------------------------------
# Name / tagging
# -----------------------------------------------------------------------------

variable "name" {
  description = "Name tag for the instance. Used in the Name tag and helpful for debugging."
  type        = string
}

variable "tags" {
  description = "Additional tags to apply to the instance. The module always sets a Name tag."
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# Network placement
# -----------------------------------------------------------------------------

variable "subnet_id" {
  description = "Subnet ID where the instance will be launched."
  type        = string
}

variable "security_group_ids" {
  description = "List of security group IDs to attach to the instance."
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Public IP behavior
# -----------------------------------------------------------------------------

variable "associate_public_ip" {
  description = <<-EOT
    Whether to assign a public IP address to the instance.

    Set this to false for instances that only need private connectivity.
    Public IPs can also be controlled at the subnet level, but this input
    makes the instance intent explicit.
  EOT
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Authentication
# -----------------------------------------------------------------------------

variable "key_name" {
  description = "Name of an existing EC2 key pair to attach to the instance. Optional."
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# Root block device
# -----------------------------------------------------------------------------

variable "root_block_device" {
  description = <<-EOT
    Configuration for the root EBS volume.

    The module sets secure defaults: encrypted, with a small gp3 size.
    You can override size, volume type, and other settings here.
  EOT
  type = object({
    encrypted             = bool
    volume_size           = number
    volume_type           = string
    delete_on_termination = bool
  })
  default = {
    encrypted             = true
    volume_size           = 10
    volume_type           = "gp3"
    delete_on_termination = true
  }

  validation {
    condition     = var.root_block_device.volume_size >= 8
    error_message = "Root volume size must be at least 8 GiB."
  }
}

# -----------------------------------------------------------------------------
# User data
# -----------------------------------------------------------------------------

variable "user_data" {
  description = "User data script to run on first boot. Optional."
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# Metadata / IMDS
# -----------------------------------------------------------------------------

variable "imdsv2_required" {
  description = <<-EOT
    If true, require IMDSv2 session tokens on the instance.

    IMDSv2 is more secure than IMDSv1 because it uses session-based tokens.
    Many organizations require IMDSv2. This module defaults to requiring it.
  EOT
  type        = bool
  default     = true
}
