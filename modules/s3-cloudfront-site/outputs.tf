output "bucket_id" {
  description = "The name (ID) of the S3 bucket."
  value       = aws_s3_bucket.site.id
}

output "bucket_arn" {
  description = "The ARN of the S3 bucket."
  value       = aws_s3_bucket.site.arn
}

output "bucket_regional_domain_name" {
  description = "The regional domain name of the S3 bucket, used for origins."
  value       = aws_s3_bucket.site.bucket_regional_domain_name
}