# Environment: prod (Production Configuration)

### This configuration defines the live, customer-facing environment. It is architected for maximum Availability (HA), Durability, and Zero-Downtime Deployment, utilizing redundancy across all layers.

I. Infrastructure Modules (Networking & Core)

- VPC (`module.vpc`): Uses a distinct, isolated CIDR range (10.1.0.0/16) from the development environment to prevent network conflicts. It uses the first two available AZs for redundancy.
- NAT Gateway (`module.nat`): Configured with High Availability (`single_nat_gateway = false`). This deploys a dedicated NAT Gateway in each public subnet/AZ, ensuring outward internet access (for updates or third-party APIs) is not a single point of failure.
- Security Groups (`module.security_groups`): Sets `enable_http = false`, enforcing HTTPS-only access from the ALB inward, a critical production security requirement.
- ECR (`module.ecr`): Forces vulnerability Scanning (`scan_on_push = true`) to ensure image security before deployment. Note: For a real production environment, force_delete should be set to false to prevent accidental deletion.
- VPC Endpoints (`module.vpc_endpoints`): Essential for security and cost, guaranteeing that all internal AWS traffic (S3, CloudWatch Logs) remains off the public internet.

II. Frontend Modules (Domain, S3, and CDN)

- S3 Site (`module.s3_site`): Hosts static content. Note: The `force_destroy = true` setting is kept for demonstration cleanup, but must be set to false in a live environment to protect against accidental data loss.
- ACM Certificate (`module.acm_cert`): Securely provisions the necessary regional (for ALB) and global (for CloudFront) SSL/TLS certificates.
- CloudFront CDN (`module.cdn`): Serves as the primary public entry point, ensuring fast content delivery and routing API traffic to the backend ALB via secure OAC credentials.

III. Backend Modules (Database and Application)

- DocumentDB (`module.docdb`): The highly available, secure data store.
  High Availability: `instance_count = 2`, deployed across two AZs for failover capability.
  Durability: High backup retention (`backup_retention_period = 14`), defined maintenance windows, and enabled logging exports (audit, profiler) for operational oversight.
  Operational Safety: Uses `apply_immediately = false` so changes are applied only during defined maintenance windows, preventing unexpected downtime.
- Application Load Balancer (`module.alb`): The primary router for the application traffic.
  High Availability: Explicitly configured to handle Blue/Green deployments (`enable_blue_green = true`) by provisioning two separate target groups.
  Security: Enforces HTTP to HTTPS redirection (`enable_http_redirect = true`) and enables cross-zone load balancing for reliable traffic distribution.
- ECS Service (`module.ecs`): The Fargate application layer.
  Zero-Downtime Deployment: The service is configured for Blue/Green Deployments (`enable_blue_green_deployment = true`), integrating with the ALB's target groups and automatically provisioning the necessary CodeDeploy resources.
  Scalability: Configured with active Autoscaling (min 2, max 8 tasks, with CPU target tracking) to dynamically handle production load.
  Security: Uses production-specific secrets (`prod/docdb/master_password`) injected via Secrets Manager, ensuring separation of concerns from the dev environment.
