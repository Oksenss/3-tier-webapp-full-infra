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


# modules/cloudfront-s3-cdn/variables.tf

variable "image_bucket_name" {
  description = "The name of the S3 bucket holding product images."
  type        = string
}

variable "image_bucket_domain_name" {
  description = "The regional domain name of the S3 bucket for images."
  type        = string
}

# Add a new output for the images OAC
output "images_oac_id" {
  description = "The ID of the Origin Access Control for the images bucket."
  value       = aws_cloudfront_origin_access_control.images_oac.id
}