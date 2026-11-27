
terraform {
  backend "s3" {
    bucket       = "terraform-aws-modular-state-sherry-2026"
    key          = "bootstrap/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
