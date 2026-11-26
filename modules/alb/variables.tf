# variables.tf — inputs for the reusable ALB module

# -----------------------------------------------------------------------------
# Naming
# -----------------------------------------------------------------------------

variable "name_prefix" {
  description = "Prefix used in ALB, target group, and listener names."
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags to apply to all resources."
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# Network placement
# -----------------------------------------------------------------------------

variable "subnet_ids" {
  description = "List of subnet IDs where the ALB will be placed. Use public subnets for internet-facing ALBs, private subnets for internal ALBs."
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID where the ALB and its resources will be created."
  type        = string
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
  description = "Existing security group ID to use instead of creating one. Takes precedence over create_security_group."
  type        = string
  default     = null
}

variable "alb_ingress_rules" {
  description = <<-EOT
    Ingress rules for the ALB security group.

    Only used when create_security_group is true and security_group_id is null.

    Example — allow HTTP from anywhere:

    ```hcl
    alb_ingress_rules = [
      {
        description = "HTTP from internet"
        protocol    = "tcp"
        from_port   = 80
        to_port     = 80
        cidr_blocks = ["0.0.0.0/0"]
      }
    ]
    ```

    Example — allow HTTPS from anywhere:

    ```hcl
    alb_ingress_rules = [
      {
        description = "HTTPS from internet"
        protocol    = "tcp"
        from_port   = 443
        to_port     = 443
        cidr_blocks = ["0.0.0.0/0"]
      }
    ]
    ```
  EOT
  type = list(object({
    description      = string
    protocol         = string
    from_port        = number
    to_port          = number
    cidr_blocks      = list(string)
    ipv6_cidr_blocks = optional(list(string))
    self             = optional(bool)
  }))
  default = []
}

variable "alb_egress_rules" {
  description = "Egress rules for the ALB security group. Same structure as alb_ingress_rules."
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

variable "internal" {
  description = "If true, the ALB is internal (no public IP). Use private subnets for internal ALBs."
  type        = bool
  default     = false
}

variable "ip_address_type" {
  description = "IP address type for the ALB: ipv4 or dualstack."
  type        = string
  default     = "ipv4"

  validation {
    condition     = contains(["ipv4", "dualstack"], var.ip_address_type)
    error_message = "ip_address_type must be 'ipv4' or 'dualstack'."
  }
}

variable "enable_deletion_protection" {
  description = "If true, protects the ALB from accidental deletion."
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
  description = "Protocol for the ALB listener: HTTP or HTTPS."
  type        = string
  default     = "HTTP"

  validation {
    condition     = contains(["HTTP", "HTTPS", "TCP", "TLS"], var.listener_protocol)
    error_message = "listener_protocol must be HTTP, HTTPS, TCP, or TLS."
  }
}

# -----------------------------------------------------------------------------
# Target group
# -----------------------------------------------------------------------------

variable "target_group_name" {
  description = "Name of the target group. Defaults to name_prefix with '-tg' suffix."
  type        = string
  default     = null
}

variable "target_group_port" {
  description = "Port for the target group."
  type        = number
  default     = 80
}

variable "target_group_protocol" {
  description = "Protocol for the target group: HTTP or HTTPS."
  type        = string
  default     = "HTTP"

  validation {
    condition     = contains(["HTTP", "HTTPS", "TCP", "TLS"], var.target_group_protocol)
    error_message = "target_group_protocol must be HTTP, HTTPS, TCP, or TLS."
  }
}

variable "target_type" {
  description = "Target type: instance, ip, or lambda."
  type        = string
  default     = "instance"

  validation {
    condition     = contains(["instance", "ip", "lambda"], var.target_type)
    error_message = "target_type must be 'instance', 'ip', or 'lambda'."
  }
}

# -----------------------------------------------------------------------------
# Health check
# -----------------------------------------------------------------------------

variable "health_check_enabled" {
  description = "Enable health checks on the target group."
  type        = bool
  default     = true
}

variable "health_check_protocol" {
  description = "Protocol for health checks: HTTP or HTTPS."
  type        = string
  default     = "HTTP"
}

variable "health_check_path" {
  description = "Path for health check requests."
  type        = string
  default     = "/"
}

variable "health_check_port" {
  description = "Port for health check requests. Can be 'traffic-port' or a number."
  type        = string
  default     = "traffic-port"
}

variable "health_check_interval" {
  description = "Time between health checks in seconds."
  type        = number
  default     = 30
}

variable "health_check_timeout" {
  description = "Time to wait for a health check response in seconds."
  type        = number
  default     = 5
}

variable "health_healthy_threshold" {
  description = "Number of consecutive successful health checks before considering the target healthy."
  type        = number
  default     = 3
}

variable "health_unhealthy_threshold" {
  description = "Number of consecutive failed health checks before considering the target unhealthy."
  type        = number
  default     = 3
}

variable "health_check_matcher" {
  description = "HTTP response codes that indicate a healthy target (e.g. '200' or '200-299')."
  type        = string
  default     = "200"
}
