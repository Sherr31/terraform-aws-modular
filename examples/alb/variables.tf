# examples/alb/variables.tf

variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short project name used in default provider tags."
  type        = string
  default     = "alb-example"
}

variable "environment" {
  description = "Environment label."
  type        = string
  default     = "dev"
}

variable "name_prefix" {
  description = "Prefix used in ALB resource names."
  type        = string
  default     = "alb-example"
}

# -----------------------------------------------------------------------------
# Network
# -----------------------------------------------------------------------------

variable "vpc_id" {
  description = "VPC ID where the ALB will be created."
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the ALB. Must be at least 2 subnets in different AZs."
  type        = list(string)
}

variable "internal" {
  description = "If true, create an internal ALB (no public IP)."
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Security
# -----------------------------------------------------------------------------

variable "create_security_group" {
  description = "Whether to create a security group for the ALB."
  type        = bool
  default     = true
}

variable "security_group_id" {
  description = "Existing security group ID to use instead of creating one."
  type        = string
  default     = null
}

variable "alb_ingress_rules" {
  description = "Ingress rules for the ALB security group."
  type = list(object({
    description      = string
    protocol         = string
    from_port        = number
    to_port          = number
    cidr_blocks      = list(string)
    ipv6_cidr_blocks = optional(list(string))
    self             = optional(bool)
  }))
  default = [
    {
      description = "HTTP from internet"
      protocol    = "tcp"
      from_port   = 80
      to_port     = 80
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

variable "alb_egress_rules" {
  description = "Egress rules for the ALB security group."
  type = list(object({
    description      = string
    protocol         = string
    from_port        = number
    to_port          = number
    cidr_blocks      = list(string)
    ipv6_cidr_blocks = optional(list(string))
    self             = optional(bool)
  }))
  default = [
    {
      description = "Allow all outbound"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

# -----------------------------------------------------------------------------
# ALB configuration
# -----------------------------------------------------------------------------

variable "ip_address_type" {
  description = "IP address type: ipv4 or dualstack."
  type        = string
  default     = "ipv4"
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection on the ALB."
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Listener
# -----------------------------------------------------------------------------

variable "listener_port" {
  description = "Port for the ALB listener."
  type        = number
  default     = 80
}

variable "listener_protocol" {
  description = "Protocol for the listener: HTTP or HTTPS."
  type        = string
  default     = "HTTP"
}

# -----------------------------------------------------------------------------
# Target group
# -----------------------------------------------------------------------------

variable "target_group_port" {
  description = "Port for the target group."
  type        = number
  default     = 80
}

variable "target_group_protocol" {
  description = "Protocol for the target group."
  type        = string
  default     = "HTTP"
}

variable "target_type" {
  description = "Target type: instance, ip, or lambda."
  type        = string
  default     = "instance"
}

# -----------------------------------------------------------------------------
# Health check
# -----------------------------------------------------------------------------

variable "health_check_path" {
  description = "Path for health check requests."
  type        = string
  default     = "/"
}

variable "health_check_protocol" {
  description = "Protocol for health checks."
  type        = string
  default     = "HTTP"
}

variable "health_check_port" {
  description = "Port for health checks (traffic-port or a number)."
  type        = string
  default     = "traffic-port"
}

variable "health_check_interval" {
  description = "Seconds between health checks."
  type        = number
  default     = 30
}

variable "health_check_timeout" {
  description = "Seconds to wait for health check response."
  type        = number
  default     = 5
}

variable "health_healthy_threshold" {
  description = "Consecutive successes before healthy."
  type        = number
  default     = 3
}

variable "health_unhealthy_threshold" {
  description = "Consecutive failures before unhealthy."
  type        = number
  default     = 3
}

variable "health_check_matcher" {
  description = "Expected HTTP response code(s)."
  type        = string
  default     = "200"
}

variable "tags" {
  description = "Additional tags to apply to all resources."
  type        = map(string)
  default     = {}
}
