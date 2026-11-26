# examples/ec2/backend.tf
#
# Remote backend for the EC2 example.
#
# Before using this:
#   1. Deploy bootstrap/terraform-state to create the S3 bucket and DynamoDB table
#   2. Replace BUCKET_NAME and LOCK_TABLE_NAME with the actual values
#   3. Run: terraform init
#
# State file: examples/ec2/terraform.tfstate
# Lock table:  from bootstrap output

terraform {
  backend "s3" {
    bucket         = "BUCKET_NAME"
    key            = "examples/ec2/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "LOCK_TABLE_NAME"
  }
}
