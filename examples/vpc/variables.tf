# examples/vpc/variables.tf

variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short project name used in default provider tags."
  type        = string
  default     = "vpc-example"
}

variable "environment" {
  description = "Environment label."
  type        = string
  default     = "dev"
}

variable "name_prefix" {
  description = "Prefix used in resource Name tags by the VPC module."
  type        = string
  default     = "vpc-example"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "Number of AZs for public and private subnets."
  type        = number
  default     = 2
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets, one per AZ."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets, one per AZ."
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "enable_nat_gateway" {
  description = "Create a NAT Gateway and Elastic IP for private subnet egress."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags to pass into the VPC module."
  type        = map(string)
  default     = {}
}
