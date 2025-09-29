# ---------------------------------------------------------------------------------------------------------------------
# ENVIRONMENT & NAMING
# ---------------------------------------------------------------------------------------------------------------------
variable "name_prefix" {
  description = "A prefix used to name all resources (e.g., 'dev' or 'prod')."
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources."
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------------------------------------------------
# NETWORKING
# ---------------------------------------------------------------------------------------------------------------------
variable "private_subnet_ids" {
  description = "A list of private subnet IDs where the ECS tasks will be placed."
  type        = list(string)
}

variable "ecs_security_group_ids" {
  description = "A list of security group IDs to attach to the ECS tasks."
  type        = list(string)
}

variable "lb_target_group_arn" {
  description = "The ARN of the Application Load Balancer target group to associate with the service."
  type        = string
}

# ---------------------------------------------------------------------------------------------------------------------
# CONTAINER & TASK DEFINITION
# ---------------------------------------------------------------------------------------------------------------------
variable "container_image" {
  description = "The ECR image URI for the container (e.g., 'account_id.dkr.ecr.region.amazonaws.com/my-repo:latest')."
  type        = string
}

variable "container_port" {
  description = "The port number on the container that is bound to the host."
  type        = number
  default     = 8080
}

variable "container_cpu" {
  description = "The number of CPU units to reserve for the container. (e.g., 256 = 0.25 vCPU)."
  type        = number
  default     = 512 # 0.5 vCPU
}

variable "container_memory" {
  description = "The amount of memory (in MiB) to reserve for the container."
  type        = number
  default     = 1024 # 1 GB
}

variable "container_environment_variables" {
  description = "A list of environment variables to pass to the container. E.g., [{name = 'DB_HOST', value = '...'}]."
  type        = list(object({
    name  = string
    value = string
  }))
  default     = []
}

variable "app_task_role_additional_policy_arns" {
  description = "A list of additional IAM policy ARNs to attach to the application task role."
  type        = list(string)
  default     = []
}

# ---------------------------------------------------------------------------------------------------------------------
# LOGGING
# ---------------------------------------------------------------------------------------------------------------------
variable "log_retention_in_days" {
  description = "The number of days to retain logs in the CloudWatch Log Group."
  type        = number
  default     = 30
}

variable "aws_region" {
  description = "The AWS region where resources are being deployed."
  type        = string
}

# ---------------------------------------------------------------------------------------------------------------------
# SERVICE & AUTOSCALING
# ---------------------------------------------------------------------------------------------------------------------
variable "desired_count" {
  description = "The initial number of tasks to launch for the service."
  type        = number
  default     = 2
}

variable "enable_autoscaling" {
  description = "A boolean flag to enable or disable autoscaling for the service."
  type        = bool
  default     = false
}

variable "autoscaling_min_tasks" {
  description = "The minimum number of tasks for autoscaling."
  type        = number
  default     = 2
}

variable "autoscaling_max_tasks" {
  description = "The maximum number of tasks for autoscaling."
  type        = number
  default     = 4
}

variable "autoscaling_cpu_threshold" {
  description = "The target CPU utilization percentage to trigger a scaling action."
  type        = number
  default     = 70
}

variable "container_secrets" {
  description = "A map of secrets to pass to the container. Key is the environment variable name, value is the full Secrets Manager ARN."
  type        = map(string)
  default     = {}
}


### NEW VARIABLES for Blue/Green Deployment ###
variable "enable_blue_green_deployment" {
  description = "If true, configure the ECS service for blue/green deployments via CodeDeploy."
  type        = bool
  default     = false
}

variable "prod_listener_arn" {
  description = "The ARN of the production ALB listener (e.g., port 443)."
  type        = string
  default     = ""
}

variable "test_listener_arn" {
  description = "The ARN of the test ALB listener for the green deployment."
  type        = string
  default     = ""
}

variable "lb_target_group_blue_name" {
  description = "The name of the blue target group."
  type        = string
  default     = ""
}

variable "lb_target_group_green_name" {
  description = "The name of the green target group."
  type        = string
  default     = ""
}
