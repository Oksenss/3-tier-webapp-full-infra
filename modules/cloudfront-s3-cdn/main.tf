# 1. Create a CloudFront Origin Access Control (OAC).
# This is the modern, secure way for CloudFront to access a private S3 bucket.
resource "aws_cloudfront_origin_access_control" "default" {
  name                              = "${var.bucket_name}-oac"
  description                       = "OAC for ${var.bucket_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

### NEW: Create a second OAC for the images bucket ###
resource "aws_cloudfront_origin_access_control" "images_oac" {
  name                              = "${var.image_bucket_name}-oac"
  description                       = "OAC for ${var.image_bucket_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}



# 2. Define managed policies for caching and headers.
# This makes the main distribution resource much cleaner.
data "aws_cloudfront_cache_policy" "caching_optimized" {
  name = "Managed-CachingOptimized"
}

data "aws_cloudfront_cache_policy" "caching_disabled" {
  name = "Managed-CachingDisabled"
}
data "aws_region" "current" {}

data "aws_cloudfront_origin_request_policy" "all_viewer" {
  name = "Managed-AllViewer"
}

data "aws_cloudfront_response_headers_policy" "security_headers" {
  name = "Managed-SecurityHeadersPolicy"
}


# 3. Define the CloudFront distribution itself.
resource "aws_cloudfront_distribution" "s3_distribution" {
  enabled             = true
  comment             = "CDN for ${var.bucket_name}"
  default_root_object = "index.html"
  price_class         = "PriceClass_100" # Use only North America and Europe
  http_version        = "http2and3"
  is_ipv6_enabled     = true

  aliases = var.domain_names

  # Origin 1: S3 bucket for the frontend application
  origin {
    origin_id   = "s3_origin_${var.bucket_name}"
    domain_name = "${var.bucket_name}.s3.${data.aws_region.current.name}.amazonaws.com"

    # CRITICAL: Connect this origin to the OAC we created above.
    origin_access_control_id = aws_cloudfront_origin_access_control.default.id
  }

  # Origin 2: ALB for the backend API
  origin {
    origin_id   = "alb_origin_backend"
    domain_name = var.backend_origin_domain

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  ### NEW: Origin 3: S3 bucket for product images ###
  origin {
    origin_id   = "s3_origin_images"
    domain_name = var.image_bucket_domain_name

    # Remove the `/images` prefix when requesting from S3
    origin_path = "/images" 

    # Connect this origin to the new images OAC
    origin_access_control_id = aws_cloudfront_origin_access_control.images_oac.id
  }

  # Default Behavior: Serve the frontend from S3
  default_cache_behavior {
    target_origin_id = "s3_origin_${var.bucket_name}"

    allowed_methods    = ["GET", "HEAD", "OPTIONS"]
    cached_methods     = ["GET", "HEAD", "OPTIONS"]
    viewer_protocol_policy = "redirect-to-https"

    cache_policy_id = data.aws_cloudfront_cache_policy.caching_optimized.id
    response_headers_policy_id = data.aws_cloudfront_response_headers_policy.security_headers.id
  }

  ### NEW: Ordered Behavior 1: Route /images/* to the images S3 bucket ###
  # This must come before the /api/* rule if you have images in your API.
  # Placed here, it's checked second, after the API.
  ordered_cache_behavior {
    path_pattern     = "/images/*"
    target_origin_id = "s3_origin_images"

    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    cache_policy_id            = data.aws_cloudfront_cache_policy.caching_optimized.id
    response_headers_policy_id = data.aws_cloudfront_response_headers_policy.security_headers.id
  }


  # Ordered Behavior 2: Route /api/* to the backend
  # This rule is checked BEFORE the default_cache_behavior.
  ordered_cache_behavior {
    path_pattern     = "/api/*"
    target_origin_id = "alb_origin_backend"

    allowed_methods    = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods     = ["GET", "HEAD", "OPTIONS"] # Only cache safe methods
    viewer_protocol_policy = "redirect-to-https"

    # IMPORTANT: These policies ensure headers (like Authorization), cookies,
    # and query strings are forwarded to your API, and that API responses are not cached.
    cache_policy_id          = data.aws_cloudfront_cache_policy.caching_disabled.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer.id
  }

  # Handle routing for Single-Page-Applications (SPAs)
  # If an object is not found (404/403), return index.html with a 200 status.
  # This allows the client-side router (React, Vue, etc.) to handle the route.
  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 10
  }
  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 10
  }


  # SSL/TLS Certificate configuration
  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none" # No geographic restrictions
    }
  }

  tags = var.tags
}