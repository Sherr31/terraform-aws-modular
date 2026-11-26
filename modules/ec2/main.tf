# main.tf — reusable EC2 instance module

# -----------------------------------------------------------------------------
# Single EC2 instance
# -----------------------------------------------------------------------------

resource "aws_instance" "this" {
  ami           = var.ami
  instance_type = var.instance_type
  subnet_id     = var.subnet_id

  # Only request a public IP when the caller explicitly wants one.
  # This keeps private-only instances private by default.
  associate_public_ip_address = var.associate_public_ip

  # Optional key pair for SSH or other key-based access.
  key_name = var.key_name

  # Use the instance name as the primary Name tag.
  tags = merge(
    var.tags,
    {
      Name = var.name
    }
  )

  # Allow the caller to pass startup configuration, for example package
  # installs or bootstrap commands. Optional.
  user_data = var.user_data

  # Root block device configuration.
  root_block_device {
    encrypted             = var.root_block_device.encrypted
    volume_size           = var.root_block_device.volume_size
    volume_type           = var.root_block_device.volume_type
    delete_on_termination = var.root_block_device.delete_on_termination
  }

  # Metadata service settings.
  #
  # IMDSv2 uses session tokens and is more resistant to certain token-leak
  # patterns than IMDSv1. Many teams require IMDSv2.
  metadata_options {
    http_tokens = var.imdsv2_required ? "required" : "optional"
  }

  # Attach the requested security groups.
  vpc_security_group_ids = var.security_group_ids
}

# -----------------------------------------------------------------------------
# Module outputs
# -----------------------------------------------------------------------------

# Output values are declared in outputs.tf so they stay consistent with the
# rest of the module contract.
