variable "name_prefix" {
  description = "A prefix used to name all resources (e.g., 'dev' or 'prod')."
  type        = string
}

variable "aws_region" {
  description = "The AWS region where endpoints are created."
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC where the endpoints will be created."
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for the Interface Endpoints."
  type        = list(string)
}

variable "private_route_table_ids" {
  description = "List of private route table IDs for the Gateway Endpoints to associate with."
  type        = list(string)
}

variable "ecs_tasks_security_group_id" {
  description = "The ID of the security group for the ECS Tasks to allow traffic from."
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources."
  type        = map(string)
  default     = {}
}