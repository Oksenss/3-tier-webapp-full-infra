output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "alb_security_group_arn" {
  description = "ARN of the ALB security group"
  value       = aws_security_group.alb.arn
}

output "ecs_tasks_security_group_id" {
  description = "ID of the ECS tasks security group"
  value       = aws_security_group.ecs_tasks.id
}

output "ecs_tasks_security_group_arn" {
  description = "ARN of the ECS tasks security group"
  value       = aws_security_group.ecs_tasks.arn
}

output "docdb_security_group_id" {
  description = "ID of the DocumentDB security group"
  value       = aws_security_group.docdb.id
}

output "docdb_security_group_arn" {
  description = "ARN of the DocumentDB security group"
  value       = aws_security_group.docdb.arn
}


output "security_groups_info" {
  description = "Summary of all security groups"
  value = {
    alb_sg_id       = aws_security_group.alb.id
    ecs_sg_id       = aws_security_group.ecs_tasks.id
    docdb_sg_id     = aws_security_group.docdb.id
    application_port = var.application_port
    database_port   = var.database_port
  }
}