# examples/ec2/main.tf
#
# Root configuration that demonstrates how to use the reusable
# modules/ec2 module.
#
# This is not a child module. It owns its own provider configuration,
# its own state, and its own outputs.
#
# State:
#   - This directory should have its own state.
#   - Do not store state inside reusable modules.
#   - In production, configure a remote backend here.

terraform {
  required_version = ">= 1.5.0"

  # Optional: configure a remote backend for this example.
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "examples/ec2/terraform.tfstate"
  #   region         = "us-east-1"
  #   use_lockfile   = true
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

# A realistic lab setup usually includes a VPC and at least one security group.
# This example is intentionally simple, but it shows how the EC2 module is
# wired to network and security inputs.

module "ec2" {
  source = "../../modules/ec2"

  ami                 = var.ami
  instance_type       = var.instance_type
  name                = "${var.name_prefix}-instance"
  subnet_id           = var.subnet_id
  security_group_ids  = concat(var.security_group_ids, [aws_security_group.example.id])
  associate_public_ip = var.associate_public_ip
  key_name            = var.key_name
  user_data           = var.user_data
  imdsv2_required     = var.imdsv2_required

  root_block_device = {
    encrypted             = true
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = var.tags
}

# A small example security group so the instance has at least one SG to attach.
# In a larger setup, this would usually come from a security group module or
# another root configuration output.

resource "aws_security_group" "example" {
  name        = "${var.name_prefix}-example-sg"
  description = "Example security group for the EC2 example."
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow SSH from a restricted source."
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_cidr_blocks
  }

  egress {
    description = "Allow all outbound traffic."
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix}-example-sg"
  }
}

