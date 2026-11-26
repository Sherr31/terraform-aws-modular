# examples/vpc/backend.tf
#
# Remote backend for the VPC example.
#
# Before using this:
#   1. Deploy bootstrap/terraform-state to create the S3 bucket and DynamoDB table
#   2. Replace BUCKET_NAME and LOCK_TABLE_NAME with the actual values
#   3. Run: terraform init
#
# The bucket name must be the actual S3 bucket name created by the bootstrap.
# The DynamoDB table name must match the bootstrap's lock table.
#
# State file: examples/vpc/terraform.tfstate
# Lock table:  from bootstrap output (e.g., terraform-state-locks)

terraform {
  backend "s3" {
    bucket         = "BUCKET_NAME" # Replace with actual bucket name
    key            = "examples/vpc/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "LOCK_TABLE_NAME" # Replace with actual DynamoDB table name
  }
}
