
variable "repository_name" {
  description = "Name of the ECR repository"
  type        = string

  validation {
    condition     = length(var.repository_name) > 1 && length(var.repository_name) <= 256
    error_message = "Repository name must be between 2 and 256 characters."
  }
}

variable "image_tag_mutability" {
  description = "Whether image tags can be overwritten"
  type        = string
  default     = "IMMUTABLE"

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "Image tag mutability must be MUTABLE or IMMUTABLE."
  }
}

variable "scan_on_push" {
  description = "Scan images for vulnerabilities when pushed"
  type        = bool
  default     = true
}

variable "encryption_type" {
  description = "Encryption type for stored images"
  type        = string
  default     = "AES256"
}

variable "force_delete" {
  description = "Allow deletion of a repository containing images"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to the ECR repository"
  type        = map(string)
  default     = {}
}
