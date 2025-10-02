# Environment: dev

### This configuration defines a cost-effective development environment. It includes a complete three-tier architecture but optimizes resources for low cost, fast iteration, and easy teardown.

I. Infrastructure Modules (Networking & Core)

- VPC (`module.vpc`): Uses a distinct, isolated CIDR range (10.1.0.0/16) from the development environment to prevent network conflicts. It uses the first two available AZs for redundancy.
- NAT Gateway (`module.nat`): Configured as a Single NAT Gateway. This is a deliberate cost-saving measure, eliminating the expense of a redundant NAT in the second AZ, which is acceptable for non-critical development.
- Security Groups (`module.security_groups`): Defines necessary network access rules. Allows both HTTP and HTTPS ingress (`enable_http = true`) for simpler testing and debugging in development.
- ECR (`module.ecr`): The repository for container images. Features `force_delete = true` (allowing quick destruction of the repository and its images) and disables scan_on_push to speed up deployment workflows.
- VPC Endpoints (`module.vpc_endpoints`): Provisions interface (CloudWatch Logs) and gateway (S3) endpoints. This security feature is maintained even in dev to ensure the ECS logging path is private and efficient.

II. Frontend Modules (Domain, S3, and CDN)

- S3 Site (`module.s3_site`): Hosts static frontend content. The bucket policy is securely configured via OAC (Origin Access Control) to only serve content to its associated CloudFront distribution.
- ACM Certificate (`module.acm_cert`): Manages SSL certificates. Provisions separate certificates for the global CloudFront distribution (in us-east-1 provider) and the regional Application Load Balancer.
- CloudFront CDN (`module.cdn`): Acts as the entry point and router. It handles edge caching for S3 content and uses the ALB as the backend origin for dynamic API calls.
- S3 Images (`module.s3_images`): A secondary S3 bucket dedicated to application images, also secured by a CloudFront-only policy.
- Route53 Records: Creates the final DNS record (`dev.my-database-vector-ai.click`) pointing to the CloudFront distribution.

III. Backend Modules (Database and Application)

- DocumentDB (`module.docdb`): The persistent data store. Highly Optimized for Cost:
  `instance_count = 1` (no high availability).
  Small instance class (`db.t3.medium`).
  Disables safety features like `skip_final_snapshot = true` and `enable_deletion_protection = false` to enable immediate, non-complex cleanup.
  Application Load Balancer (`module.alb`): Exposes the ECS service. `enable_deletion_protection = false` ensures quick teardown upon destruction.
- ECS Service (`module.ecs`): The Fargate service running the application container.
  Minimal Footprint: Set to a fixed `desired_count = 1 ` with `enable_autoscaling = false` for tight cost control.
- Configuration: Connects to the DocumentDB endpoint via environment variables, and securely receives sensitive keys (passwords, JWT secrets) via the Fargate Secrets integration with Systems Manager.
