output "distribution_id" {
  description = "The ID of the CloudFront distribution."
  value       = aws_cloudfront_distribution.s3_distribution.id
}

output "distribution_domain_name" {
  description = "The domain name corresponding to the distribution."
  value       = aws_cloudfront_distribution.s3_distribution.domain_name
}

output "distribution_hosted_zone_id" {
  description = "The CloudFront Route 53 hosted zone ID for alias records."
  value       = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
}
