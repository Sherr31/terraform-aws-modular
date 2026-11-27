
variable "name" {
  description = "Name of the Application Load Balancer"
  type        = string

  validation {
    condition     = length(var.name) >= 2 && length(var.name) <= 32
    error_message = "ALB name must be between 2 and 32 characters."
  }
}

variable "internal" {
  description = "Whether the ALB is internal"
  type        = bool
  default     = false
}

variable "security_group_ids" {
  description = "Security groups attached to the ALB"
  type        = list(string)
}

variable "subnet_ids" {
  description = "Subnets where the ALB will be deployed"
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "An ALB requires at least two subnets."
  }
}

variable "target_port" {
  description = "Port on which targets receive traffic"
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "Health check path"
  type        = string
  default     = "/"
}

variable "tags" {
  description = "Tags applied to ALB resources"
  type        = map(string)
  default     = {}
}

variable "vpc_id" {
  description = "VPC ID where the target group will be created"
  type        = string
}
