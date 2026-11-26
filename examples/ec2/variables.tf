# examples/ec2/variables.tf

variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short project name used in default provider tags."
  type        = string
  default     = "ec2-example"
}

variable "environment" {
  description = "Environment label."
  type        = string
  default     = "dev"
}

variable "name_prefix" {
  description = "Prefix used in resource names for this example."
  type        = string
  default     = "ec2-example"
}

# -----------------------------------------------------------------------------
# AMI
# -----------------------------------------------------------------------------

variable "ami" {
  description = <<-EOT
    AMI ID for the instance.

    This example uses a placeholder AMI ID. In a real run, use a region-aware
    AMI lookup or pass in the AMI you want.
  EOT
  type        = string
  default     = "ami-0c55b159cbfafe1f0"
}

# -----------------------------------------------------------------------------
# Instance
# -----------------------------------------------------------------------------

variable "instance_type" {
  description = "Instance type."
  type        = string
  default     = "t3.micro"
}

variable "subnet_id" {
  description = "Subnet ID where the instance will be launched."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID used by the example security group."
  type        = string
}

variable "security_group_ids" {
  description = "Security group IDs to attach to the instance."
  type        = list(string)
  default     = []
}

variable "associate_public_ip" {
  description = "Whether to assign a public IP address to the instance."
  type        = bool
  default     = false
}

variable "key_name" {
  description = "Name of an existing EC2 key pair to attach. Optional."
  type        = string
  default     = null
}

variable "user_data" {
  description = "User data script to run on first boot. Optional."
  type        = string
  default     = null
}

variable "imdsv2_required" {
  description = "If true, require IMDSv2 session tokens."
  type        = bool
  default     = true
}

variable "root_volume_size" {
  description = "Root EBS volume size in GiB."
  type        = number
  default     = 10
}

variable "ssh_cidr_blocks" {
  description = "CIDR blocks allowed to reach the instance on port 22."
  type        = list(string)
  default     = ["10.0.0.0/8"]
}

variable "tags" {
  description = "Additional tags to apply to the instance."
  type        = map(string)
  default     = {}
}
