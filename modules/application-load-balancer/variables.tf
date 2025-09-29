variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for ALB and related resource names"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where ALB will be created"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for ALB placement"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs to attach to ALB"
  type        = list(string)
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS listener"
  type        = string
}

variable "target_port" {
  description = "Port that targets receive traffic on"
  type        = number
  default     = 8080
}

variable "target_protocol" {
  description = "Protocol to use for routing traffic to targets"
  type        = string
  default     = "HTTP"
}

variable "health_check_path" {
  description = "Health check path"
  type        = string
  default     = "/api/health"
}

variable "health_check_interval" {
  description = "Health check interval in seconds"
  type        = number
  default     = 30
}

variable "health_check_timeout" {
  description = "Health check timeout in seconds"
  type        = number
  default     = 5
}

variable "health_check_healthy_threshold" {
  description = "Number of consecutive health checks successes required"
  type        = number
  default     = 2
}

variable "health_check_unhealthy_threshold" {
  description = "Number of consecutive health check failures required"
  type        = number
  default     = 2
}

variable "health_check_matcher" {
  description = "Response codes to use when checking for a healthy responses"
  type        = string
  default     = "200"
}

variable "enable_http_redirect" {
  description = "Enable HTTP to HTTPS redirect listener"
  type        = bool
  default     = true
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection for ALB"
  type        = bool
  default     = false
}

variable "idle_timeout" {
  description = "Connection idle timeout in seconds"
  type        = number
  default     = 60
}

variable "enable_cross_zone_load_balancing" {
  description = "Enable cross-zone load balancing"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}


##################################################
# NEW VARIABLE FOR BLUE/GREEN DEPLOYMENT         #
##################################################
variable "enable_blue_green" {
  description = "If true, create two target groups (blue/green) and a test listener."
  type        = bool
  default     = false
}

variable "test_listener_port" {
  description = "The port to use for the test listener that points to the green deployment."
  type        = number
  default     = 8443
}
