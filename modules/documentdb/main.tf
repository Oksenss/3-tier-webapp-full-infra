#########################################################
# Local values                                         #
#########################################################

locals {
  cluster_identifier = "${var.environment}-docdb-cluster"

  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      Module      = "documentdb"
    }
  )
}

#########################################################
# Random Suffix for Final Snapshot                     #
#########################################################

# [ADDED] Create a stable random suffix for the snapshot identifier
# This prevents terraform from showing a change on every apply.
resource "random_string" "snapshot_suffix" {
  length  = 8
  special = false
  upper   = false
}

#########################################################
# Data Sources                                         #
#########################################################

data "aws_secretsmanager_secret" "docdb_password" {
  name = var.secrets_manager_secret_name
}

data "aws_secretsmanager_secret_version" "docdb_password" {
  secret_id = data.aws_secretsmanager_secret.docdb_password.id
}

# [KEPT] This data source is used to add the AZ tag to instances.
data "aws_subnet" "private" {
  count = length(var.private_subnet_ids)
  id    = var.private_subnet_ids[count.index]
}

#########################################################
# DocumentDB Subnet Group                              #
#########################################################

resource "aws_docdb_subnet_group" "main" {
  name       = "${var.environment}-docdb-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = merge(
    local.common_tags,
    {
      Name = "${var.environment}-docdb-subnet-group"
    }
  )
}

#########################################################
# DocumentDB Parameter Group                           #
#########################################################

resource "aws_docdb_cluster_parameter_group" "main" {
  name   = "${var.environment}-docdb-params"
  family = var.docdb_family # [CHANGED] Made configurable

  parameter {
    name  = "tls"
    value = "enabled"
  }

  parameter {
    name  = "ttl_monitor"
    value = "enabled"
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${var.environment}-docdb-parameter-group"
    }
  )
}

#########################################################
# DocumentDB Cluster                                   #
#########################################################

resource "aws_docdb_cluster" "main" {
  cluster_identifier           = local.cluster_identifier
  engine                       = "docdb"
  engine_version               = var.engine_version
  master_username              = var.master_username
  master_password              = data.aws_secretsmanager_secret_version.docdb_password.secret_string
  port                         = var.port
  db_subnet_group_name         = aws_docdb_subnet_group.main.name
  vpc_security_group_ids       = var.security_group_ids

  backup_retention_period      = var.backup_retention_period
  preferred_backup_window      = var.backup_window
  preferred_maintenance_window = var.maintenance_window

  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${local.cluster_identifier}-final-snapshot-${random_string.snapshot_suffix.result}"

  storage_encrypted             = var.storage_encrypted
  deletion_protection           = var.enable_deletion_protection
  db_cluster_parameter_group_name = aws_docdb_cluster_parameter_group.main.name
  apply_immediately             = var.apply_immediately
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports # [CHANGED] Made configurable


  # Add this line for major version upgrades
  allow_major_version_upgrade = var.allow_major_version_upgrade
  
  tags = merge(
    local.common_tags,
    {
      Name = local.cluster_identifier
    }
  )
}

#########################################################
# DocumentDB Cluster Instances                         #
#########################################################

resource "aws_docdb_cluster_instance" "main" {
  count              = var.instance_count
  identifier         = "${var.environment}-docdb-instance-${count.index + 1}"
  cluster_identifier = aws_docdb_cluster.main.id
  instance_class     = var.instance_class

  apply_immediately = var.apply_immediately

  tags = merge(
    local.common_tags,
    {
      Name = "${var.environment}-docdb-instance-${count.index + 1}"
      # [KEPT] The data source is used here to add a helpful AZ tag.
      AZ = data.aws_subnet.private[count.index % length(var.private_subnet_ids)].availability_zone
    }
  )
}