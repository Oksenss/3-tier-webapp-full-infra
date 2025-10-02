# ECS Module

### What It Does

Deploys a containerized application to AWS Fargate, incorporating all necessary supporting infrastructure for production use, including IAM roles, logging, autoscaling, and secure secrets injection.

- Core Resources: Creates the ECS Cluster (`aws_ecs_cluster.main`), Task Definition (`aws_ecs_task_definition.app`), and Service (`aws_ecs_service.app`).
- Security & IAM: Sets up two necessary IAM roles:
  - Task Execution Role: Used by ECS to pull images and write logs. Includes a policy to allow reading secrets from Secrets Manager.
  - Application Task Role: Used by the application inside the container to access other AWS services.
- Secrets Integration: Securely injects environment variables directly from AWS Secrets Manager into the container definition.
- Observability: Creates a dedicated CloudWatch Log Group (`aws_cloudwatch_log_group.app`) and configures the container logging driver.
- High Availability: Implements optional CPU-based target tracking autoscaling (`aws_appautoscaling_policy.cpu_scaling`).

### Conditional Feature: Blue/Green Deployment

If `var.enable_blue_green_deployment` is `true`, the module deploys advanced CI/CD infrastructure:

- CodeDeploy Integration: Configures the ECS Service deployment controller to use `CODE_DEPLOY`.
- Deployment Group: Creates the CodeDeploy Application and Deployment Group (`aws_codedeploy_deployment_group.app`), linking the ECS service to the required Blue/Green target groups and traffic listeners (received via input variables), ensuring zero-downtime, validated deployments.
- CodeDeploy IAM: Provisions and attaches the necessary AWSCodeDeployRoleForECS IAM role.
