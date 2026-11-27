
variable "aws_region" {
  description = "AWS region for bootstrap resources"
  type        = string
  default     = "us-east-1"
}

variable "state_bucket_name" {
  description = "Existing S3 bucket for Terraform remote state"
  type        = string
  default     = "terraform-aws-modular-state-sherry-2026"
}

variable "github_repository" {
  description = "GitHub repository allowed to assume the deployment role"
  type        = string
  default     = "Sherr31/terraform-aws-modular"
}

variable "github_actions_role_name" {
  description = "Existing IAM role used by GitHub Actions"
  type        = string
  default     = "github-actions-terraform"
}
