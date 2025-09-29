# output "cluster_name" {
#   description = "The name of the ECS cluster."
#   value       = aws_ecs_cluster.main.name
# }

# output "service_name" {
#   description = "The name of the ECS service."
#   value       = aws_ecs_service.app.name
# }

# output "task_definition_arn" {
#   description = "The ARN of the ECS task definition."
#   value       = aws_ecs_task_definition.app.arn
# }

# output "app_task_role_arn" {
#   description = "The ARN of the IAM role for the application task."
#   value       = aws_iam_role.app_task_role.arn
# }

# output "log_group_name" {
#   description = "The name of the CloudWatch log group for the application."
#   value       = aws_cloudwatch_log_group.app.name
# }

# ### NEW OUTPUTS ###
# output "codedeploy_app_name" {
#   description = "The name of the CodeDeploy application."
#   value       = var.enable_blue_green_deployment ? aws_codedeploy_app.app[0].name : null
# }

# output "codedeploy_deployment_group_name" {
#   description = "The name of the CodeDeploy deployment group."
#   value       = var.enable_blue_green_deployment ? aws_codedeploy_deployment_group.app[0].name : null
# }


# modules/ecs/outputs.tf

output "cluster_name" {
  description = "The name of the ECS cluster."
  value       = aws_ecs_cluster.main.name
}

output "service_name" {
  description = "The name of the ECS service."
  value       = aws_ecs_service.app.name
}

output "task_definition_arn" {
  description = "The ARN of the ECS task definition."
  value       = aws_ecs_task_definition.app.arn
}

output "app_task_role_arn" {
  description = "The ARN of the IAM role for the application task."
  value       = aws_iam_role.app_task_role.arn
}

output "log_group_name" {
  description = "The name of the CloudWatch log group for the application."
  value       = aws_cloudwatch_log_group.app.name
}

output "codedeploy_app_name" {
  description = "The name of the CodeDeploy application."
  value       = var.enable_blue_green_deployment ? aws_codedeploy_app.app[0].name : null
}

output "codedeploy_deployment_group_name" {
  description = "The name of the CodeDeploy deployment group."
  ### CORRECTED LINE ###
  value       = var.enable_blue_green_deployment ? aws_codedeploy_deployment_group.app[0].deployment_group_name : null
}