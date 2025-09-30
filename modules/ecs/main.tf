#########################################################
# Local Values & Data Sources                          #
#########################################################
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  container_name = "${var.name_prefix}-app-container"
  
  common_tags = merge(
    var.tags,
    {
      Module = "ecs"
    }
  )
}

#########################################################
# CloudWatch Log Group                                 #
#########################################################

resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${var.name_prefix}/app"
  retention_in_days = var.log_retention_in_days

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name_prefix}-app-logs"
    }
  )
}

#########################################################
# IAM Roles                                            #
#########################################################

# --- Role needed by ECS to manage tasks (pulling images, writing logs) ---
resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${var.name_prefix}-ecs-task-execution-role"
  tags               = local.common_tags
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# --- Role for the application inside the container to access other AWS services ---
resource "aws_iam_role" "app_task_role" {
  name               = "${var.name_prefix}-app-task-role"
  tags               = local.common_tags
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

# Attach any additional custom policies passed in
resource "aws_iam_role_policy_attachment" "app_task_additional_policies" {
  count      = length(var.app_task_role_additional_policy_arns)
  role       = aws_iam_role.app_task_role.name
  policy_arn = var.app_task_role_additional_policy_arns[count.index]
}

#####################################
### NEW - IAM Role for CodeDeploy ###
#####################################

resource "aws_iam_role" "codedeploy_role" {
  count = var.enable_blue_green_deployment ? 1 : 0

  name = "${var.name_prefix}-codedeploy-role"
  tags = local.common_tags
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "codedeploy.amazonaws.com"
      }
    }]
  })
}


resource "aws_iam_role_policy_attachment" "codedeploy_policy_attachment" {
  count = var.enable_blue_green_deployment ? 1 : 0

  role       = aws_iam_role.codedeploy_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
}

#########################################
#########################################
#########################################

#########################################################
# ECS Cluster & Task Definition                        #
#########################################################

resource "aws_ecs_cluster" "main" {
  name = "${var.name_prefix}-cluster"
  tags = merge(
    local.common_tags,
    {
      Name = "${var.name_prefix}-cluster"
    }
  )
}

resource "aws_ecs_task_definition" "app" {
  family                   = "${var.name_prefix}-app-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.container_cpu
  memory                   = var.container_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.app_task_role.arn

  container_definitions = jsonencode([
    {
      name      = local.container_name
      image     = var.container_image
      essential = true
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]
      environment = var.container_environment_variables

      # NEW: Securely inject secrets from Secrets Manager
      secrets = [for name, value_from in var.container_secrets : {
        name      = name
        valueFrom = value_from
      }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.app.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "app"
        }
      }
    }
  ])

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name_prefix}-app-task"
    }
  )
}

#########################################################
# ECS Service & Load Balancing                         #
#########################################################

###########################################################
# NEW - ECS Service with CodeDeploy Blue/Green Deployment #
###########################################################

resource "aws_ecs_service" "app" {
  name    = "${var.name_prefix}-app-service"
  cluster = aws_ecs_cluster.main.id
  # For CodeDeploy, the task definition is specified in the appspec file during deployment
  task_definition    = aws_ecs_task_definition.app.arn 
  desired_count      = var.desired_count
  launch_type        = "FARGATE"
  
  ### NEW - Deployment Controller ###
  deployment_controller {
    type = var.enable_blue_green_deployment ? "CODE_DEPLOY" : "ECS" # Use CodeDeploy if enabled
  }

  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = var.ecs_security_group_ids
  }

  load_balancer {
    target_group_arn = var.lb_target_group_arn # This will be the BLUE target group
    container_name   = local.container_name
    container_port   = var.container_port
  }

  lifecycle {
    ignore_changes = [
      desired_count,
      task_definition # IMPORTANT: Allow CodeDeploy to manage the task definition version
    ]
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name_prefix}-app-service"
    }
  )
}


### NEW - CodeDeploy Application ###
resource "aws_codedeploy_app" "app" {
  count = var.enable_blue_green_deployment ? 1 : 0

  name             = "${var.name_prefix}-app"
  compute_platform = "ECS"
  tags             = local.common_tags
}

resource "aws_codedeploy_deployment_group" "app" {
  count = var.enable_blue_green_deployment ? 1 : 0

  app_name               = aws_codedeploy_app.app[0].name
  deployment_group_name  = "${var.name_prefix}-dg"
  service_role_arn       = aws_iam_role.codedeploy_role[0].arn
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce" # Shift traffic immediately after successful tests

  ecs_service {
    cluster_name = aws_ecs_cluster.main.name
    service_name = aws_ecs_service.app.name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [var.prod_listener_arn]
      }
      test_traffic_route {
        listener_arns = [var.test_listener_arn]
      }
      target_group {
        name = var.lb_target_group_blue_name
      }
      target_group {
        name = var.lb_target_group_green_name
      }
    }
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  blue_green_deployment_config {
    # ADD THIS REQUIRED BLOCK
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
      # Optional: wait_time_in_minutes = 0  # Default is 0 for immediate deployment
    }

    # This section defines what happens to the old "blue" tasks after a successful deployment
    terminate_blue_instances_on_deployment_success {
      # Terminate the old tasks to save costs.
      action = "TERMINATE" 
      # How long to wait before terminating the old tasks, allowing for connection draining.
      termination_wait_time_in_minutes = 5 
    }
  }



  tags = local.common_tags
}

### END - CodeDeploy Blue/Green Deployment ###

#########################################################
# ECS Autoscaling (Optional)                           #
#########################################################

resource "aws_appautoscaling_target" "ecs_service" {
  count              = var.enable_autoscaling ? 1 : 0
  max_capacity       = var.autoscaling_max_tasks
  min_capacity       = var.autoscaling_min_tasks
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.app.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "cpu_scaling" {
  count              = var.enable_autoscaling ? 1 : 0
  name               = "${var.name_prefix}-cpu-scaling-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_service[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_service[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_service[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = var.autoscaling_cpu_threshold
  }
}




#########################################################
# Addditional Policies & Outputs                         #
#########################################################

# Add this policy to allow ECS to read secrets from Secrets Manager
resource "aws_iam_policy" "secrets_manager_access" {
  name        = "${var.name_prefix}-secrets-manager-access"
  description = "Allow ECS tasks to read secrets from Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:dev/proshop/app_secrets-*",
          "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:dev/docdb/master_password-*",
          "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:dev/app/admin_credentials-*",
          "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:prod/proshop/app_secrets-*",
          "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:prod/docdb/master_password-*",
          "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:prod/app/admin_credentials-*",
          "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:prod/credentials/proshop-*"
        ]
      }
    ]
  })
}

# Attach the policy to the ECS task execution role
resource "aws_iam_role_policy_attachment" "ecs_secrets_manager_access" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.secrets_manager_access.arn
}

