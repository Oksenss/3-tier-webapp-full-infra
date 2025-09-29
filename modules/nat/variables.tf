variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where NAT gateway will be created"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for NAT gateway placement"
  type        = list(string)
}

# variable "private_subnet_ids" {
#   description = "List of private subnet IDs to associate with NAT route tables"
#   type        = list(string)
# }

variable "single_nat_gateway" {
  description = "Whether to use a single NAT gateway for all AZs (cost optimization)"
  type        = bool
  default     = false
}

# Add to modules/nat/main.tf (or a variables.tf in that module)

variable "private_route_table_ids" {
  description = "List of private route table IDs to add the NAT route to."
  type        = list(string)
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}