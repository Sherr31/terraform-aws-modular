# examples/alb/backend.tf
#
# Remote backend for the ALB example.
#
# Before using this:
#   1. Deploy bootstrap/terraform-state to create the S3 bucket and DynamoDB table
#   2. Replace BUCKET_NAME and LOCK_TABLE_NAME with the actual values
#   3. Run: terraform init
#
# State file: examples/alb/terraform.tfstate
# Lock table:  from bootstrap output

terraform {
  backend "s3" {
    bucket         = "BUCKET_NAME"
    key            = "examples/alb/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "LOCK_TABLE_NAME"
  }
}
