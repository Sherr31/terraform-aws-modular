
variable "name" {
  description = "Name of the security group"
  type        = string

  validation {
    condition     = length(trimspace(var.name)) > 0
    error_message = "Security group name cannot be empty."
  }
}

variable "description" {
  description = "Description of the security group"
  type        = string
  default     = "Managed by Terraform"
}

variable "vpc_id" {
  description = "ID of the VPC where the security group will be created"
  type        = string
}

variable "ingress_rules" {
  description = "Inbound security group rules"
  type = list(object({
    description = optional(string)
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = optional(list(string), [])
  }))
  default = []
}

variable "egress_rules" {
  description = "Outbound security group rules"
  type = list(object({
    description = optional(string)
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = optional(list(string), ["0.0.0.0/0"])
  }))
  default = []
}

variable "tags" {
  description = "Tags applied to the security group"
  type        = map(string)
  default     = {}
}
