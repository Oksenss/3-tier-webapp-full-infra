# Security Groups Module

### What It Does

Deploys the three fundamental security groups required for a typical containerized application stack (ALB, ECS, and Database). This module establishes the critical communication flow and segmentation:

- ALB Security Group (`aws_security_group.alb`): Opens ports 80 (optional) and 443 to the internet (`var.allowed_cidr_blocks`).
- ECS Task Security Group (`aws_security_group.ecs_tasks`): Allows ingress only from the ALB Security Group on the application port (`var.application_port`), effectively isolating the application from direct internet access.
- DocumentDB Security Group (`aws_security_group.docdb`): Allows ingress only from the ECS Tasks Security Group on the database port (`var.database_port`), creating a secure database layer
