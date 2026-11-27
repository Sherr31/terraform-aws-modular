
variable "role_name" {
  description = "Name of the IAM role"
  type        = string

  validation {
    condition     = length(trimspace(var.role_name)) > 0
    error_message = "IAM role name cannot be empty."
  }
}

variable "description" {
  description = "Description of the IAM role"
  type        = string
  default     = "Managed by Terraform"
}

variable "trusted_entity" {
  description = "AWS service allowed to assume this role"
  type        = string
  default     = "ec2.amazonaws.com"
}

variable "policy_arns" {
  description = "List of managed IAM policy ARNs to attach"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags applied to the IAM role"
  type        = map(string)
  default     = {}
}
