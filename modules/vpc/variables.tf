
variable "name" {
  description = "Name prefix for VPC resources"
  type        = string

  validation {
    condition     = length(trimspace(var.name)) > 0
    error_message = "The VPC name must not be empty."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "Provide a valid VPC CIDR block."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]

  validation {
    condition = (
      length(var.public_subnet_cidrs) > 0 &&
      length(distinct(var.public_subnet_cidrs)) == length(var.public_subnet_cidrs) &&
      alltrue([for cidr in var.public_subnet_cidrs : can(cidrnetmask(cidr))])
    )
    error_message = "Public subnet CIDRs must be valid, unique CIDR blocks."
  }
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]

  validation {
    condition = (
      length(var.private_subnet_cidrs) > 0 &&
      length(distinct(var.private_subnet_cidrs)) == length(var.private_subnet_cidrs) &&
      alltrue([for cidr in var.private_subnet_cidrs : can(cidrnetmask(cidr))])
    )
    error_message = "Private subnet CIDRs must be valid, unique CIDR blocks."
  }
}

variable "availability_zones" {
  description = "Optional availability zones; defaults to the first available AZs"
  type        = list(string)
  default     = []

  validation {
    condition = (
      length(distinct(var.availability_zones)) ==
      length(var.availability_zones)
    )
    error_message = "Availability zones must not contain duplicates."
  }
}

variable "enable_dns_support" {
  description = "Enable DNS resolution in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "enable_nat_gateway" {
  description = "Create NAT Gateway for private subnet internet access"
  type        = bool
  default     = false
}

variable "single_nat_gateway" {
  description = "Use one NAT Gateway instead of one per AZ"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags applied to resources"
  type        = map(string)
  default     = {}
}
