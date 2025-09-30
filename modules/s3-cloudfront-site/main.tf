# 1. Create a private S3 bucket.
resource "aws_s3_bucket" "site" {
  bucket = var.bucket_name

  force_destroy = var.force_destroy
  
  tags = merge(
    {
      "Name" = "${var.bucket_name}-site-bucket"
    },
    var.tags
  )
}

# 2. Apply a strict Public Access Block policy to the bucket.
# This is a non-negotiable security measure. We hard-code these values to 'true'
# to ensure any bucket created by this module is private by default.
resource "aws_s3_bucket_public_access_block" "site" {
  bucket = aws_s3_bucket.site.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "site_versioning" {
  bucket = aws_s3_bucket.site.id
  versioning_configuration {
    status = "Enabled"
  }
}
