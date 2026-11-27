
variable "app_name" {
  description = "Application name"
  type        = string
  default     = "app-two"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.20.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.20.1.0/24", "10.20.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.20.11.0/24", "10.20.12.0/24"]
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Existing AWS EC2 key pair name"
  type        = string
  default     = "aws-secure-vpc"
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

variable "db_identifier" {
  description = "RDS database identifier"
  type        = string
  default     = "app-two-postgres"
}

variable "tags" {
  description = "Common application tags"
  type        = map(string)
  default = {
    Environment = "dev"
    Project     = "terraform-aws-modular"
  }
}
