
resource "aws_db_subnet_group" "this" {
  name       = "${var.identifier}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, {
    Name      = "${var.identifier}-subnet-group"
    ManagedBy = "Terraform"
    Module    = "rds"
  })
}

resource "aws_db_instance" "this" {
  identifier = var.identifier

  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = var.storage_encrypted

  db_name  = var.db_name
  username = var.username

  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = var.vpc_security_group_ids

  backup_retention_period = var.backup_retention_period
  multi_az                = var.multi_az

  publicly_accessible = var.publicly_accessible
  deletion_protection = var.deletion_protection

  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : var.final_snapshot_identifier

  auto_minor_version_upgrade = true
  copy_tags_to_snapshot      = true

  tags = merge(var.tags, {
    Name      = var.identifier
    ManagedBy = "Terraform"
    Module    = "rds"
  })

  lifecycle {
    precondition {
      condition = (
        var.skip_final_snapshot ||
        var.final_snapshot_identifier != null
      )
      error_message = "Provide final_snapshot_identifier when skip_final_snapshot is false."
    }
  }
}
