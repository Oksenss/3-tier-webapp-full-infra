# ACM Certificate Provisioning

### What It Does

Manages the full lifecycle (request, DNS validation, and validation wait) for two distinct AWS Certificate Manager (ACM) certificates:

- CloudFront Certificate (`aws_acm_certificate.cloudfront_cert`): Requests a certificate always provisioned in the `us-east-1` region, which is mandatory for use with AWS CloudFront.
- Regional Certificate (Conditional): Requests a separate certificate in the local working AWS region for use with regional services like Application Load Balancers (ALB).

### Why It's Structured This Way

- CloudFront Requirement: Explicitly uses a `provider = aws.us_east_1` configuration alias to satisfy - CloudFront's strict requirement that all associated SSL certificates reside in the N. Virginia region.
- Dual Provider Management: Uses the default provider for creating the necessary validation records in Route53 (`aws_route53_record.cloudfront_cert_validation`) and the `us-east-1` alias for the certificate creation and validation resources.
