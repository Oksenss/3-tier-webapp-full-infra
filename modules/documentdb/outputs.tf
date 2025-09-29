output "cluster_id" {
  description = "DocumentDB cluster identifier"
  value       = aws_docdb_cluster.main.id
}

output "cluster_arn" {
  description = "DocumentDB cluster ARN"
  value       = aws_docdb_cluster.main.arn
}

output "cluster_resource_id" {
  description = "DocumentDB cluster resource ID"
  value       = aws_docdb_cluster.main.cluster_resource_id
}

output "cluster_endpoint" {
  description = "DocumentDB cluster endpoint (writer)"
  value       = aws_docdb_cluster.main.endpoint
}

output "reader_endpoint" {
  description = "DocumentDB cluster reader endpoint"
  value       = aws_docdb_cluster.main.reader_endpoint
}

output "port" {
  description = "DocumentDB port"
  value       = aws_docdb_cluster.main.port
}

output "master_username" {
  description = "DocumentDB master username"
  value       = aws_docdb_cluster.main.master_username
  sensitive   = true # This is a good practice to prevent accidental exposure in logs.
}

output "hosted_zone_id" {
  description = "DocumentDB hosted zone ID"
  value       = aws_docdb_cluster.main.hosted_zone_id
}

output "instance_endpoints" {
  description = "List of DocumentDB instance endpoints"
  value       = aws_docdb_cluster_instance.main[*].endpoint
}

output "availability_zones" {
  description = "List of AZs where instances are deployed"
  value       = aws_docdb_cluster_instance.main[*].availability_zone
}

output "cluster_members" {
  description = "List of DocumentDB instance identifiers in the cluster"
  value       = aws_docdb_cluster.main.cluster_members
}

output "connection_info" {
  description = "Convenience map with common DocumentDB connection information"
  value = {
    cluster_endpoint = aws_docdb_cluster.main.endpoint
    reader_endpoint  = aws_docdb_cluster.main.reader_endpoint
    port             = aws_docdb_cluster.main.port
    master_username  = aws_docdb_cluster.main.master_username
  }
  sensitive = true # Mark as sensitive because it contains the username.
}


