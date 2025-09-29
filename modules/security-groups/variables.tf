variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where security groups will be created"
  type        = string
}

variable "application_port" {
  description = "Port that the backend application listens on"
  type        = number
  default     = 8080
}

variable "database_port" {
  description = "Port for the database (DocumentDB/MongoDB)"
  type        = number
  default     = 27017
}

variable "enable_http" {
  description = "Whether to allow HTTP traffic on ALB (in addition to HTTPS)"
  type        = bool
  default     = true
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access the ALB"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "allowed_ipv6_cidr_blocks" {
  description = "IPv6 CIDR blocks allowed to access the ALB"
  type        = list(string)
  default     = ["::/0"]
}

variable "additional_alb_ports" {
  description = "Additional ports to open on ALB security group"
  type = list(object({
    port        = number
    protocol    = string
    description = string
  }))
  default = []
}

variable "additional_ecs_ingress" {
  description = "Additional ingress rules for ECS tasks"
  type = list(object({
    port            = number
    protocol        = string
    description     = string
    source_sg_ids   = list(string)
    cidr_blocks     = list(string)
  }))
  default = []
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}