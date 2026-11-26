# bootstrap/terraform-state/variables.tf

variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short project name used in default provider tags."
  type        = string
  default     = "terraform-aws-modular"
}

variable "environment" {
  description = "Environment label."
  type        = string
  default     = "prod"
}

variable "bucket_name" {
  description = <<-EOT
    Name of the S3 bucket for Terraform state.

    Bucket names must be globally unique across all of AWS. Use a name that
    includes your project and is unlikely to collide with other buckets.

    Example: "mycompany-terraform-state-123456789012"
  EOT
  type        = string
}

variable "lock_table_name" {
  description = "Name of the DynamoDB table for state locking."
  type        = string
  default     = "terraform-state-locks"
}

variable "force_destroy" {
  description = <<-EOT
    Allow the S3 bucket to be destroyed even if it contains objects.

    Set to true only in non-production environments. In production, leave
    this false to prevent accidental destruction of state.
  EOT
  type        = bool
  default     = false
}

variable "create_access_policy" {
  description = "Whether to create the IAM policy for Terraform state access."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags to apply to all resources."
  type        = map(string)
  default     = {}
}
