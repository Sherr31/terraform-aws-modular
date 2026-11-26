# variables.tf — inputs the calling app must (or can) pass into this module

variable "name_prefix" {
  description = "Prefix used in resource Name tags (e.g. web-api-dev)."
  type        = string
}

variable "cidr_block" {
  description = "CIDR block for the VPC (e.g. 10.0.0.0/16)."
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "Number of AZs to use for public/private subnets."
  type        = number
  default     = 2

  validation {
    condition     = var.az_count >= 1 && var.az_count <= 3
    error_message = "This module supports az_count between 1 and 3 for this lab."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (one per AZ)."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]

  validation {
    condition     = length(var.public_subnet_cidrs) == var.az_count
    error_message = "public_subnet_cidrs must have exactly az_count entries."
  }
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (one per AZ)."
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]

  validation {
    condition     = length(var.private_subnet_cidrs) == var.az_count
    error_message = "private_subnet_cidrs must have exactly az_count entries."
  }
}

variable "enable_nat_gateway" {
  description = <<-EOT
    If true, create one NAT Gateway and one Elastic IP for private subnet outbound
    internet access.

    Cost warning: a NAT Gateway is not free. Disable it for cheap labs that do not
    need private subnet internet access.
  EOT
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags to apply to all resources in this module."
  type        = map(string)
  default     = {}
}

locals {
  public_cidr_count  = length(var.public_subnet_cidrs)
  private_cidr_count = length(var.private_subnet_cidrs)
}
