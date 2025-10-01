# This special block declares that the module expects to receive multiple provider configurations.
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
      configuration_aliases = [aws.us_east_1]
    }
  }
}

# 1. Request a new SSL certificate in the us-east-1 region for CloudFront.
resource "aws_acm_certificate" "cloudfront_cert" {
  provider                  = aws.us_east_1 # <-- CRITICAL: Must be us-east-1 for CloudFront
  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]
  validation_method         = "DNS"

  tags = merge(var.tags, {
    Purpose = "CloudFront"
    Region  = "us-east-1"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# 2. Create the necessary DNS validation records in your primary Hosted Zone.
resource "aws_route53_record" "cloudfront_cert_validation" {
  # This resource uses the default provider passed to the module (e.g., eu-central-1)
  for_each = {
    for dvo in aws_acm_certificate.cloudfront_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.zone_id
}

# 3. Wait for the certificate to be validated by AWS in us-east-1.
resource "aws_acm_certificate_validation" "cloudfront_cert" {
  provider                = aws.us_east_1 # <-- CRITICAL: Must be us-east-1 for CloudFront
  certificate_arn         = aws_acm_certificate.cloudfront_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cloudfront_cert_validation : record.fqdn]
}

#########################################################
# Regional Certificate (for ALB)                        #
#########################################################

# 4. Request a new SSL certificate in the regional provider for ALB
resource "aws_acm_certificate" "regional_cert" {
  count = var.create_regional_certificate ? 1 : 0
  
  # Uses default provider (eu-central-1)
  domain_name               = var.domain_name
  subject_alternative_names = concat(["*.${var.domain_name}"], var.subject_alternative_names)
  validation_method         = "DNS"

  tags = merge(var.tags, {
    Purpose = "ALB"
    Region  = "regional"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# 5. Create DNS validation records for regional certificate
resource "aws_route53_record" "regional_cert_validation" {
  for_each = var.create_regional_certificate ? {
    for dvo in aws_acm_certificate.regional_cert[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.zone_id
}

# 6. Wait for the regional certificate to be validated
resource "aws_acm_certificate_validation" "regional_cert" {
  count = var.create_regional_certificate ? 1 : 0
  
  certificate_arn         = aws_acm_certificate.regional_cert[0].arn
  validation_record_fqdns = [for record in aws_route53_record.regional_cert_validation : record.fqdn]

  timeouts {
    create = "5m"
  }
}
