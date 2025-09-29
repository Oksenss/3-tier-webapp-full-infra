# CloudFront Certificate Outputs
output "certificate_arn" {
  description = "The ARN of the validated ACM certificate for CloudFront (us-east-1)."
  value       = aws_acm_certificate_validation.cloudfront_cert.certificate_arn
}

output "cloudfront_certificate_arn" {
  description = "The ARN of the CloudFront certificate (us-east-1)."
  value       = aws_acm_certificate_validation.cloudfront_cert.certificate_arn
}

# Regional Certificate Outputs
output "regional_certificate_arn" {
  description = "The ARN of the regional certificate for ALB."
  value       = var.create_regional_certificate ? aws_acm_certificate_validation.regional_cert[0].certificate_arn : null
}

output "alb_certificate_arn" {
  description = "The ARN of the ALB certificate (regional)."
  value       = var.create_regional_certificate ? aws_acm_certificate_validation.regional_cert[0].certificate_arn : null
}

# Convenience outputs
output "certificates" {
  description = "All certificate ARNs"
  value = {
    cloudfront = aws_acm_certificate_validation.cloudfront_cert.certificate_arn
    alb        = var.create_regional_certificate ? aws_acm_certificate_validation.regional_cert[0].certificate_arn : null
  }
}