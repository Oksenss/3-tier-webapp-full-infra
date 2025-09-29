variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where DocumentDB will be created"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for DocumentDB placement"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs to attach to DocumentDB"
  type        = list(string)
}

variable "master_username" {
  description = "Master username for DocumentDB cluster"
  type        = string
  default     = "docdbadmin"
}

variable "secrets_manager_secret_name" {
  description = "Name of the secret in AWS Secrets Manager containing the master password"
  type        = string
}

variable "instance_count" {
  description = "Number of DocumentDB instances to create"
  type        = number
  default     = 1
}

variable "instance_class" {
  description = "Instance class for DocumentDB instances"
  type        = string
  default     = "db.t3.medium"
}

variable "backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
}

variable "backup_window" {
  description = "Backup window in UTC (format: hh24:mi-hh24:mi)"
  type        = string
  default     = "04:00-05:00"
}

variable "maintenance_window" {
  description = "Maintenance window in UTC (format: ddd:hh24:mi-ddd:hh24:mi)"
  type        = string
  default     = "sun:05:00-sun:06:00"
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection (recommended for production)"
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot when deleting cluster (true for demos/dev)"
  type        = bool
  default     = true
}

variable "storage_encrypted" {
  description = "Enable encryption at rest"
  type        = bool
  default     = true
}

variable "apply_immediately" {
  description = "Apply changes immediately or during maintenance window"
  type        = bool
  default     = true
}

variable "engine_version" {
  description = "DocumentDB engine version"
  type        = string
  default     = "5.0.0"
}

variable "docdb_family" {
  description = "DocumentDB parameter group family"
  type        = string
  default     = "docdb5.0"  # Change from docdb3.6 to docdb5.0
}

variable "port" {
  description = "Port for DocumentDB cluster"
  type        = number
  default     = 27017
}

# [ADDED] New variable to make log exports configurable.
variable "enabled_cloudwatch_logs_exports" {
  description = "List of log types to export to CloudWatch Logs. Valid values: 'audit', 'profiler'."
  type        = list(string)
  default     = ["audit", "profiler"]
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "allow_major_version_upgrade" {
  description = "Enable major version upgrades"
  type        = bool
  default     = false
}