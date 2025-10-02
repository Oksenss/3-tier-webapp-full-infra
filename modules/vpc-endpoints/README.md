# Secure VPC Endpoints

### What It Does

This module provisions secure VPC Endpoints to enable private communication between resources in the VPC (e.g., ECS Tasks) and key AWS services, reducing data transfer costs and increasing security by keeping traffic off the public internet.

- S3 Gateway Endpoint (`aws_vpc_endpoint.s3`): Creates a Gateway Endpoint for S3 and automatically injects the necessary routes into the private route tables (`var.private_route_table_ids`).
- CloudWatch Logs Interface Endpoint (`aws_vpc_endpoint.logs`): Creates an Interface Endpoint for - CloudWatch Logs, a critical component for containerized logging.
- VPC Endpoint Security: Creates a dedicated security group (`aws_security_group.vpc_endpoints_sg`) that explicitly allows ingress on port 443 only from the ECS Task Security Group (`var.ecs_tasks_security_group_id`), ensuring only the application layer can communicate with the endpoints.
