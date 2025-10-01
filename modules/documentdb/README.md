# DocumentDB Cluster

### What It Does

Deploys an Amazon DocumentDB (MongoDB-compatible) cluster across multiple Availability Zones, managing the cluster, instances, and necessary configuration elements.

- Cluster High-Availability: Deploys a cluster (`aws_docdb_cluster.main`) and corresponding instances (`aws_docdb_cluster_instance.main`) distributed across the private subnets provided.
- Security & Networking:
  - Creates a Subnet Group (`aws_docdb_subnet_group.main`) dedicated to the private subnets.
  - Integrates with a dedicated Security Group (`var.security_group_ids`) to control access.
- Parameter & Best Practices: Enforces best practice configurations via a Parameter Group (`aws_docdb_cluster_parameter_group.main`), including essential settings like `tls = "enabled"`.
- Secret Management: Retrieves the cluster master password securely from AWS Secrets Manager (`data.aws_secretsmanager_secret_version.docdb_password`).
- Reliability: Manages highly configurable backup windows, retention periods, and conditional final snapshot creation.

### Why It's Structured This Way

- Separation of Concerns: Clearly separates the cluster definition (the database container) from the instance definition (the compute nodes) for streamlined scaling and HA.
- Secrets Integration: Uses Secrets Manager for database credentials, preventing sensitive data from being stored in plan files or state, which is crucial for compliance.
- AZ Distribution: The instance tags use modulo logic `(count.index % length(var.private_subnet_ids))` to ensure instances are evenly spread across the provided subnets for maximum resilience.
