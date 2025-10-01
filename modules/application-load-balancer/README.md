# Application Load Balancer (ALB) Module

### What It Does

Deploys a public-facing Application Load Balancer (ALB) configured for high availability and secure HTTPS traffic, with optional Blue/Green deployment support.

- Load Balancing (`aws_lb.main`): Provisions an Internet-facing ALB across public subnets, secured by a required security_group_ids input.
- Secure Listening: Configures HTTPS (443) listener (`aws_lb_listener.https`) using an imported SSL certificate (`var.certificate_arn`). It optionally includes an HTTP (80) listener to enforce a 301 redirect to HTTPS.
- Conditional Target Groups: Based on var.enable_blue_green, it provisions either:
- A single target group (`aws_lb_target_group.app_single`) for standard operation.
  Paired Blue and Green target groups (`app_blue, app_green`) for zero-downtime deployment strategies.
  Blue/Green Support: When enabled, it creates an additional test listener (`aws_lb_listener.https_test`) on an alternate port that always points to the Green environment for pre-deployment validation.

### Why It's Structured This Way

- Flexibility via Conditionals: Using `count = var.enable_blue_green ? 1 : 0` allows the same module to serve simple development environments (`single TG`) and complex production environments (`Blue/Green`).
- Security Standard: Enforces HTTPS for the primary listener and offers an optional HTTP redirect listener (`var.enable_http_redirect`) to ensure all traffic uses encryption.
  Target Group Management: The target groups are configured to support IP targets (`target_type = "ip"`), which is the standard required when running containerized workloads like AWS Fargate.
