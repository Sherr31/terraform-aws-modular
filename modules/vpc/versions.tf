# versions.tf — pins Terraform and provider versions for this module only

terraform {                     # Start of Terraform settings block for this module
  required_version = ">= 1.5.0" # Require Terraform CLI 1.5 or newer

  required_providers {          # Declare which providers this module needs
    aws = {                     # Configure the AWS provider requirement
      source  = "hashicorp/aws" # Official HashiCorp AWS provider source
      version = ">= 5.0, < 6.0" # Allow AWS provider 5.x only (avoid breaking 6.x)
    }                           # End aws provider map
  }                             # End required_providers
}                               # End terraform block
