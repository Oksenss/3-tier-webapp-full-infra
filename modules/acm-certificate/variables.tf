variable "domain_name" {
  description = "The domain name for which to create the certificate (e.g., 'example.com' or 'dev.example.com')."
  type        = string
}

variable "zone_id" {
  description = "The ID of the Route 53 Hosted Zone for creating validation records."
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the certificate."
  type        = map(string)
  default     = {}
}

# NEW VARIABLES
variable "create_regional_certificate" {
  description = "Whether to create a regional certificate for ALB (in addition to us-east-1 for CloudFront)"
  type        = bool
  default     = false
}

variable "subject_alternative_names" {
  description = "Additional domain names to include in the certificate"
  type        = list(string)
  default     = []
}