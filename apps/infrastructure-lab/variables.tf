# apps/infrastructure-lab/variables.tf

# -----------------------------------------------------------------------------
# AWS region
# -----------------------------------------------------------------------------

variable "aws_region" {
  description = "AWS region to deploy the application into."
  type        = string
  default     = "us-east-1"
}

# -----------------------------------------------------------------------------
# Naming
# -----------------------------------------------------------------------------

variable "name_prefix" {
  description = "Prefix used in resource names (e.g. web-api-dev)."
  type        = string
  default     = "infra-lab"
}

variable "environment" {
  description = "Environment label (e.g. dev, staging, prod)."
  type        = string
  default     = "dev"
}

# -----------------------------------------------------------------------------
# Network
# -----------------------------------------------------------------------------

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "Number of AZs to use (1-3)."
  type        = number
  default     = 2
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (one per AZ)."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (one per AZ)."
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

# -----------------------------------------------------------------------------
# AMI and instance type
# -----------------------------------------------------------------------------

variable "ami" {
  description = <<-EOT
    AMI ID for EC2 instances in the Auto Scaling group.

    This must be a valid AMI ID in your selected region. To find one:

      aws ec2 describe-images \
        --owners amazon \
        --filters "Name=name,Values=al2023-ami-2023.*-x86_64" \
        --query "Images[0].ImageId" \
        --region us-east-1

    Amazon Linux 2023 is recommended. The AMI ID differs per region.
  EOT
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for the Auto Scaling group."
  type        = string
  default     = "t3.micro"
}

# -----------------------------------------------------------------------------
# ASG sizing
# -----------------------------------------------------------------------------

variable "asg_min_size" {
  description = "Minimum number of instances in the ASG."
  type        = number
  default     = 1
}

variable "asg_max_size" {
  description = "Maximum number of instances in the ASG."
  type        = number
  default     = 2
}

variable "asg_desired_capacity" {
  description = "Desired number of instances in the ASG."
  type        = number
  default     = 1
}

# -----------------------------------------------------------------------------
# ALB
# -----------------------------------------------------------------------------

variable "alb_listener_port" {
  description = "Port for the ALB listener."
  type        = number
  default     = 80
}

variable "app_port" {
  description = "Port the application listens on inside EC2 instances."
  type        = number
  default     = 8080
}

# -----------------------------------------------------------------------------
# Tags
# -----------------------------------------------------------------------------

variable "tags" {
  description = "Additional tags to apply to all resources."
  type        = map(string)
  default     = {}
}
