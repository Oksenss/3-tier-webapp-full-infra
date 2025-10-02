# CDN (CloudFront) Module

### What It Does

Deploys a robust CloudFront Distribution designed to unify static content (S3) and dynamic API traffic (ALB) under a single domain name.

- Dual Origin Setup: Configures two primary origins:
  - A secure, private S3 bucket (via Origin Access Control, `aws_cloudfront_origin_access_control.default`).
  - A backend Application Load Balancer (`var.backend_origin_domain`).
- Intelligent Routing: Uses ordered cache behaviors to route paths:
  - Requests matching /api/\* are sent to the ALB origin with caching explicitly disabled (`caching_disabled`) to ensure real-time interaction.
  - Requests matching /images/\* are sent to the s3 bucket for retrieval of images with optimized caching (`caching_optimized`).
  - All other requests default to the S3 bucket origin with optimized caching enabled.
- SPA Rewriting: Uses custom_error_response rules to redirect 403 and 404 errors to /index.html with a 200 status code, allowing the client-side router (React Router) to handle the application's internal routes.

### Why It's Structured This Way

- Security: Uses OAC (the successor to OAI) to correctly secure the S3 origin, ensuring data is only accessible via the CloudFront distribution.
- Performance: Uses high-performance caching policies for static assets while ensuring API traffic remains dynamic and uncached.
- Simplification: Consolidates the frontend and backend under one hostname, simplifying SSL handling (`var.acm_certificate_arn`) and domain configuration.
