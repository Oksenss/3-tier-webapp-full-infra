#############################
# 1. Set up the AWS provider#
#############################

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
  backend "s3" {
    bucket         = "my-blue-green-depl-tf-state"
    key            = "tf-state-prod"
    region         = "eu-central-1"
    use_lockfile = true
    encrypt = true
  }
}

# Default provider for main infrastructure in eu-central-1
provider "aws" {
  region = var.aws_region
}

# Additional provider for resources that must be in us-east-1 (e.g., ACM for CloudFront)
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

# Get first 2 AZs for prod
data "aws_availability_zones" "available" {
  state = "available"
}


#############################
# 2. Local Values           #
#############################
locals {
    prod_azs           = slice(data.aws_availability_zones.available.names, 0, 2)
    domain_name        = "my-database-vector-ai.click"
    parent_domain_name = "my-database-vector-ai.click" # ### MODIFIED ### - Added for consistency
    environment        = "prod"
    prefix             = "prod" # ### ADDED ### - Added for consistency
    image_bucket_name  = "${local.prefix}-proshop-images" # Will be "prod-proshop-images"
}

#############################
# 3. Data Sources           #
#############################
data "aws_route53_zone" "primary" {
  name         = local.parent_domain_name 
  private_zone = false
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

#############################
# 4. VPC Module Usage     #
#############################

module "vpc" {
  source = "../../modules/vpc"
  
  environment = "prod"
  vpc_cidr    = "10.1.0.0/16"  # Different CIDR from dev
  
  availability_zones     = local.prod_azs
  public_subnet_cidrs   = ["10.1.1.0/24", "10.1.2.0/24"]           # 2 public subnets
  private_subnet_cidrs  = ["10.1.10.0/24", "10.1.11.0/24"]         # 2 private subnets
}



#############################
# 5. ECR Module Usage     #
#############################

module "ecr" {
  source = "../../modules/ecr"

  repository_name = "project1-prod"
  scan_on_push    = true # Enable scanning to catch issues before prod
  force_delete = true # [REAL PROD SETTING] false
}

#############################
# 6. NAT Gateway Module     #
#############################

module "nat" {
  source = "../../modules/nat"

  environment         = local.environment
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  single_nat_gateway = false  # High availability - one NAT per AZ

  private_route_table_ids = module.vpc.private_route_table_ids

  tags = {
    Environment = local.environment
  }
}

#############################
# 7. Security Groups Module #
#############################

module "security_groups" {
  source = "../../modules/security-groups"

  environment      = local.environment
  vpc_id          = module.vpc.vpc_id
  application_port = 8080  # Your backend app port
  database_port   = 27017  # DocumentDB port
  enable_http     = false   # Set to false if you want HTTPS-only in prod

  tags = {
    Environment = local.environment
  }
}

######################################
######################################
# FRONTEND PART                      #
######################################
######################################


#############################
# 1. S3 Frontend Site Bucket#
#############################
module "s3_site" {
  source = "../../modules/s3-cloudfront-site"

  # false for prod to prevent accidental deletions
  force_destroy = true # [REAL PROD SETTING] false
  bucket_name = local.domain_name
  tags = {
    Environment = local.environment
  }
}



#############################
# 2. ACM Certificate Module #
#############################

module "acm_cert" {
  source = "../../modules/acm-certificate"

  providers = {
    aws.us_east_1 = aws.us_east_1
  }

  domain_name = local.domain_name
  zone_id     = data.aws_route53_zone.primary.zone_id

  create_regional_certificate = true # For ALB in the future
  tags = {
    Environment = local.environment
  }
}


#############################
# 3. CDN Module             #
#############################


# Create the CloudFront Distribution
module "cdn" {
  source = "../../modules/cloudfront-s3-cdn"

  bucket_name         = module.s3_site.bucket_id
  acm_certificate_arn = module.acm_cert.certificate_arn
  domain_names        = [local.domain_name]

  # For now, we use a placeholder. Later, we'll replace this
  # with the real ALB domain name from our backend module.
  backend_origin_domain = module.alb.alb_dns_name

  image_bucket_name        = module.s3_images.bucket_id
  image_bucket_domain_name = module.s3_images.bucket_domain_name

  tags = { Environment = local.environment }
}

# Create the S3 bucket policy to allow access ONLY from our CloudFront distribution
resource "aws_s3_bucket_policy" "allow_cloudfront" {
  bucket = module.s3_site.bucket_id
  policy = data.aws_iam_policy_document.s3_policy_document.json
}

# This policy document is used by the resource above
data "aws_iam_policy_document" "s3_policy_document" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${module.s3_site.bucket_arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = ["arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${module.cdn.distribution_id}"]
    }
  }
}


resource "aws_s3_bucket_policy" "allow_cloudfront_images" {
  bucket = module.s3_images.bucket_id
  policy = data.aws_iam_policy_document.s3_images_policy_document.json
}

data "aws_iam_policy_document" "s3_images_policy_document" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${module.s3_images.bucket_arn}/*"] # Policy applies to objects inside /images folder

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = ["arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${module.cdn.distribution_id}"]
    }
  }
}



# Create the final DNS "A" record to point our domain to the CloudFront distribution
resource "aws_route53_record" "site_dns" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = local.domain_name
  type    = "A"

  alias {
    name                   = module.cdn.distribution_domain_name
    zone_id                = module.cdn.distribution_hosted_zone_id
    evaluate_target_health = false
  }
}
#############################
# 4. S3 Images   #
#############################


module "s3_images" {
  source = "../../modules/s3-images"

  bucket_name = local.image_bucket_name
  tags = {
    Environment = local.environment
  }
}


######################################
######################################
# BACKEND PART                       #
######################################
######################################


############################
# 1. DocumentDB Database   #
############################

module "docdb" {
  source = "../../modules/documentdb"

  vpc_id = module.vpc.vpc_id

  environment         = local.environment
  private_subnet_ids  = module.vpc.private_subnet_ids
  security_group_ids  = [module.security_groups.docdb_security_group_id]

  # Production configuration - 2 instances across multiple AZs
  instance_count               = 2
  instance_class               = "db.t3.medium"
  
  # Production backup and maintenance settings
  backup_retention_period      = 14  # 2 weeks retention for production
  backup_window               = "03:00-04:00"  # During low-traffic hours
  maintenance_window          = "sun:04:00-sun:05:00"  # Sunday morning maintenance
  
  # Production security and reliability settings
  # skip_final_snapshot          = false  # [REAL PROD SETTING] Always create final snapshot in 
  # enable_deletion_protection   = true   # [REAL PROD SETTING] Protect against accidental deletion in 
  skip_final_snapshot          = true  # Always create final snapshot in prod
  enable_deletion_protection   = false   # Protect against accidental deletion
  apply_immediately            = false  # Use maintenance windows for changes
  storage_encrypted            = true   # Encrypt data at rest
  
  # Engine and logging configuration
  engine_version              = "5.0.0"
  docdb_family               = "docdb5.0"
  enabled_cloudwatch_logs_exports = ["audit", "profiler"]  # Full logging for prod
  
  # Authentication settings (for now getting dev secret - replace later)
  master_username              = "prodadmin"  
  secrets_manager_secret_name = "prod/docdb/master_password"  # Production secret
  port                        = 27017

  tags = {
    Environment = local.environment
    Backup      = "Required"
    Critical    = "true"
  }
}

#############################
# 2. ALB Module             #
#############################

module "alb" {
  source = "../../modules/application-load-balancer"

  enable_blue_green = true

  environment        = local.environment
  name_prefix        = local.environment # Will create "prod-alb", "prod-blue-tg", "prod-green-tg"
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  security_group_ids = [module.security_groups.alb_security_group_id]

  # Certificate for HTTPS (using the regional cert from the updated module)
  certificate_arn = module.acm_cert.alb_certificate_arn

  # Application configuration
  target_port     = 8080
  target_protocol = "HTTP"

  # Health check configuration
  health_check_path = "/api/health"

  # Production-ready settings
  # enable_deletion_protection     = true  # [REAL PROD SETTING] CRITICAL for production
  enable_deletion_protection = false
  enable_http_redirect         = true  # Good practice to redirect HTTP to HTTPS
  enable_cross_zone_load_balancing = true  # Recommended for high availability

  tags = {
    Environment = local.environment
    Purpose     = "Prod"
  }
}


#############################
# 3. ECS Module             #
#############################
module "ecs" {
  source = "../../modules/ecs"

  ### MODIFIED ###
  enable_blue_green_deployment = true

  image_bucket_arn = module.s3_images.bucket_arn

  
  # Wire the ALB and listeners to the ECS module
  prod_listener_arn         = module.alb.https_listener_arn
  test_listener_arn         = module.alb.test_listener_arn
  lb_target_group_arn       = module.alb.target_group_blue_arn # Service initially points to blue
  lb_target_group_blue_name  = module.alb.target_group_blue_name 
  lb_target_group_green_name = module.alb.target_group_green_name          # Must match name from ALB module

  name_prefix       = local.prefix
  aws_region        = var.aws_region

  # Networking
  private_subnet_ids     = module.vpc.private_subnet_ids
  ecs_security_group_ids = [module.security_groups.ecs_tasks_security_group_id]
  
  # Container & Task Definition
  container_image      = "${module.ecr.repository_url}:latest" # This will be overwritten by CI/CD
  container_port       = 8080
  
  # Pass individual components as environment variables
  container_environment_variables = [
    {
      name  = "DOCUMENTDB_ENDPOINT"
      value = module.docdb.cluster_endpoint
    },
    {
      name  = "PAGINATION_LIMIT" 
      value = "20" # Production might have a higher limit
    },
    {
      name  = "DOCUMENTDB_PORT"
      value = "27017"
    },
    {
      name  = "DOCUMENTDB_USERNAME"
      value = "prodadmin"
    }, 
    {
      # Tells the backend which S3 bucket to upload to
      name  = "AWS_IMAGES_BUCKET_NAME"
      value = module.s3_images.bucket_id
    }
  ]
  
  # Pass secrets from Secrets Manager. Note we are using PRODUCTION secrets.
  container_secrets = merge({
    "DOCUMENTDB_PASSWORD" = "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:prod/docdb/master_password"
    # The following secrets are from 'prod/proshop/app_secrets' based on your screenshot
    "PORT"                = "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:prod/proshop/app_secrets:PORT::"
    "PAYPAL_CLIENT_ID"    = "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:prod/proshop/app_secrets:PAYPAL_CLIENT_ID::"
    "JWT_SECRET"          = "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:prod/proshop/app_secrets:JWT_SECRET::"
    "ENV"                 = "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:prod/proshop/app_secrets:ENV::"
  }, {
      # This is our newly added admin secret for the prod environment
      "ADMIN_CREDENTIALS" = "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:prod/credentials/proshop-EzZIV4"
    })
  
  # Production-ready service & autoscaling configuration (UNCHANGED)
  desired_count      = 2
  enable_autoscaling = true
  autoscaling_min_tasks = 2
  autoscaling_max_tasks = 8
  autoscaling_cpu_threshold = 70

  tags = {
    Environment = local.environment
    Critical    = "true"
  }
}


##################################
# 4. VPC Endpoints Module        #
##################################

module "vpc_endpoints" {
  source = "../../modules/vpc-endpoints"

  name_prefix       = local.environment
  aws_region        = var.aws_region
  vpc_id            = module.vpc.vpc_id

  # Provide outputs from other modules
  private_subnet_ids          = module.vpc.private_subnet_ids
  private_route_table_ids     = module.vpc.private_route_table_ids # From our new VPC output
  ecs_tasks_security_group_id = module.security_groups.ecs_tasks_security_group_id

  tags = {
    Environment = local.environment
  }
}


#############################
# Outputs                   #
#############################

output "environment_info" {
  value = {
    environment = local.environment
    vpc_id = module.vpc.vpc_id
    public_subnets = length(module.vpc.public_subnet_ids)
    private_subnets = length(module.vpc.private_subnet_ids)
  }
}


output "nat_gateway_info" {
  description = "NAT Gateway information"
  value = {
    nat_gateway_ids     = module.nat.nat_gateway_ids
    elastic_ips        = module.nat.elastic_ip_addresses
    nat_gateway_count  = module.nat.nat_gateway_count
  }
}

output "ecr_repository_url" {
  description = "The URL of the prod ECR repository"
  value       = module.ecr.repository_url
}
# Add to existing outputs section
output "ecs_info" {
  description = "Key information from the ECS module."
  value = {
    cluster_name = module.ecs.cluster_name
    service_name = module.ecs.service_name
    log_group    = module.ecs.log_group_name
  }
}

output "cloudfront_distribution_id" {
  description = "CloudFront Distribution ID"
  value       = module.cdn.distribution_id
  
}

output "vpc_endpoints_info" {
  description = "Information about the created VPC Endpoints."
  value = {
    security_group_id = module.vpc_endpoints.vpc_endpoints_security_group_id
  }
}

# Add this new output block to your existing outputs
output "docdb_cluster_endpoint" {
  description = "The connection endpoint for the DocumentDB cluster."
  value       = module.docdb.cluster_endpoint
  sensitive   = true # The endpoint reveals infrastructure details
}

# Add these to your outputs section
output "alb_info" {
  description = "Application Load Balancer information"
  value = module.alb.load_balancer_info
}

output "alb_dns_name" {
  description = "ALB DNS name for backend integration"
  value = module.alb.alb_dns_name
}


# Add to existing outputs section
output "security_groups_info" {
  description = "Security group information"
  value       = module.security_groups.security_groups_info
}

output "security_group_ids" {
  description = "Security group IDs for use by other resources"
  value = {
    alb_sg_id     = module.security_groups.alb_security_group_id
    ecs_sg_id     = module.security_groups.ecs_tasks_security_group_id
    docdb_sg_id   = module.security_groups.docdb_security_group_id
  }
}

# Add a new output to confirm creation
output "s3_site_bucket_id" {
  description = "ID of the S3 bucket for the frontend static site."
  value       = module.s3_site.bucket_id
}

output "acm_certificate_arn" {
  description = "ARN of the validated ACM certificate for CloudFront."
  value       = module.acm_cert.certificate_arn
}


output "cloudfront_distribution_domain" {
  description = "Domain name for the CloudFront distribution."
  value       = module.cdn.distribution_domain_name
  }

output "website_url" {
  description = "The final URL for the dev environment website."
  value       = "https://${local.domain_name}"
}

### NEW - Outputs for CI/CD ###
output "codedeploy_app_name" {
    description = "CodeDeploy Application Name for CI/CD."
    value       = module.ecs.codedeploy_app_name
}

output "codedeploy_deployment_group_name" {
    description = "CodeDeploy Deployment Group Name for CI/CD."
    value       = module.ecs.codedeploy_deployment_group_name
}