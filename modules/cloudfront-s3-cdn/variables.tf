variable "bucket_name" {
  description = "The name of the S3 bucket serving the frontend content."
  type        = string
}

variable "domain_names" {
  description = "A list of custom domain names for the CloudFront distribution (e.g., ['dev.example.com'])."
  type        = list(string)
}

variable "acm_certificate_arn" {
  description = "The ARN of the AWS Certificate Manager (ACM) certificate."
  type        = string
}

variable "backend_origin_domain" {
  description = "The domain name of the backend origin (e.g., the ALB)."
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the resources."
  type        = map(string)
  default     = {}
}