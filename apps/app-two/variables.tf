
variable "app_name" {
  description = "Application name"
  type        = string
  default     = "app-two"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "bucket_name" {
  description = "Globally unique S3 bucket name"
  type        = string
  default     = "terraform-aws-modular-app-two-055111817997"
}

variable "ecr_repository_name" {
  description = "ECR repository name"
  type        = string
  default     = "app-two"
}

variable "ecr_image_tag" {
  description = "ECR image tag (commit SHA) to deploy"
  type        = string
  default     = "latest"
}

variable "db_identifier" {
  description = "RDS database identifier"
  type        = string
  default     = "app-two-postgres"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "dbadmin"
}

variable "tags" {
  description = "Common application tags"
  type        = map(string)
  default = {
    Environment = "dev"
    Project     = "terraform-aws-modular"
  }
}
