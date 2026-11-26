# examples/security-group/variables.tf

variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short project name used in default provider tags."
  type        = string
  default     = "sg-example"
}

variable "environment" {
  description = "Environment label."
  type        = string
  default     = "dev"
}

variable "name_prefix" {
  description = "Prefix used in resource names for this example."
  type        = string
  default     = "sg-example"
}

variable "vpc_id" {
  description = "VPC ID where the security group will be created."
  type        = string
}

# -----------------------------------------------------------------------------
# Ingress rules
# -----------------------------------------------------------------------------

variable "ingress_rules" {
  description = "List of ingress rules for the security group."
  type = list(object({
    protocol         = string
    from_port        = number
    to_port          = number
    cidr_blocks      = list(string)
    ipv6_cidr_blocks = optional(list(string))
    prefix_list_ids  = optional(list(string))
    security_groups  = optional(list(string))
    self             = optional(bool)
    description      = optional(string)
  }))
  default = [
    {
      protocol    = "tcp"
      from_port   = 80
      to_port     = 80
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTP from internet"
    },
    {
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTPS from internet"
    }
  ]
}

# -----------------------------------------------------------------------------
# Egress rules
# -----------------------------------------------------------------------------

variable "egress_rules" {
  description = "List of egress rules for the security group."
  type = list(object({
    protocol         = string
    from_port        = number
    to_port          = number
    cidr_blocks      = list(string)
    ipv6_cidr_blocks = optional(list(string))
    prefix_list_ids  = optional(list(string))
    security_groups  = optional(list(string))
    self             = optional(bool)
    description      = optional(string)
  }))
  default = [
    {
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTPS outbound"
    },
    {
      protocol    = "tcp"
      from_port   = 80
      to_port     = 80
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTP outbound"
    }
  ]
}

variable "tags" {
  description = "Additional tags to apply to the security group."
  type        = map(string)
  default     = {}
}
