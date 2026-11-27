
variable "app_name" {
  description = "Application name"
  type        = string
  default     = "app-one"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.10.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.10.1.0/24", "10.10.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.10.11.0/24", "10.10.12.0/24"]
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
  default     = "terraform-aws-modular-app-one-055111817997"
}

variable "ecr_repository_name" {
  description = "ECR repository name"
  type        = string
  default     = "app-one"
}

variable "tags" {
  description = "Common application tags"
  type        = map(string)
  default = {
    Environment = "dev"
    Project     = "terraform-aws-modular"
  }
}
