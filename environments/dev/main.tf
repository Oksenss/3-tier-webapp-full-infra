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
    bucket         = "my-blue-green-depl-tf-state" # <---- Use your bucket name
    key            = "tf-state-dev"
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

data "aws_availability_zones" "available" {
  state = "available"
}


#############################
# 2. Local Values           #
#############################

locals {
    dev_azs = slice(data.aws_availability_zones.available.names, 0, 2)
    domain_name = "dev.my-database-vector-ai.click" # <---- DEFINE YOUR DOMAIN HERE
    environment = "dev"
    parent_domain_name  = "my-database-vector-ai.click" # <---- DEFINE YOUR DOMAIN HERE
    prefix = "dev"
    image_bucket_name = "${local.prefix}-proshop-images"
}


#############################
# 3. Data Sources           #
#############################
data "aws_route53_zone" "primary" {
  name         = local.parent_domain_name
  private_zone = false
}


#############################
# 4. VPC Module Usage     #
#############################

module "vpc" {
    source              = "../../modules/vpc"
    environment         = "dev"
    vpc_cidr            = "10.0.0.0/16"

    availability_zones  = local.dev_azs
    public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
    private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
}

#############################
# 5. ECR Module Usage     #
#############################


module "ecr" {
  source = "../../modules/ecr"

  repository_name = "project1-dev"
  scan_on_push    = false # Disabled for dev to speed up pushes
  force_delete    = true  # OK for a non-critical dev environment
}

#############################
# 6. NAT Gateway Module     #
#############################

module "nat" {
  source = "../../modules/nat"

  environment         = local.environment
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids

  private_route_table_ids = module.vpc.private_route_table_ids

  single_nat_gateway = true  

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
  enable_http     = true   # Allow both HTTP and HTTPS in dev

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

  create_regional_certificate = true # We need a regional cert for ALB
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

data "aws_caller_identity" "current" {}


resource "aws_s3_bucket_policy" "allow_cloudfront_images" {
  bucket = module.s3_images.bucket_id
  policy = data.aws_iam_policy_document.s3_images_policy_document.json
}

data "aws_iam_policy_document" "s3_images_policy_document" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${module.s3_images.bucket_arn}/images/*"] # Policy applies to objects inside /images folder

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
# 1. DocumentDB Database    #
#############################

module "docdb" {
  source = "../../modules/documentdb" # Assuming the path to your docdb module

  vpc_id = module.vpc.vpc_id

  environment         = local.environment
  private_subnet_ids  = module.vpc.private_subnet_ids
  security_group_ids  = [module.security_groups.docdb_security_group_id]

  # Engine version upgrade
  engine_version               = "5.0.0"
  allow_major_version_upgrade  = true  # Add this line
  docdb_family                = "docdb5.0"  # Update to match engine version

  # Configuration for a small, cost-effective dev environment
  instance_count               = 1 # Only one instance for dev
  instance_class               = "db.t3.medium" # Small, burstable instance type
  backup_retention_period      = 3 # Keep backups for 3 days
  skip_final_snapshot          = true # Don't create a final snapshot when destroying dev
  enable_deletion_protection   = false # Allow easy destruction in dev
  apply_immediately            = true
  
  # Parameters for connecting to the cluster
  master_username              = "devadmin"
  secrets_manager_secret_name = "dev/docdb/master_password" # The secret we created
  port                       = 27017

  tags = {
    Environment = local.environment
  }
}

#############################
# 2. ALB Module             #
#############################

module "alb" {
  source = "../../modules/application-load-balancer"

  environment        = local.environment
  name_prefix       = local.prefix
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  security_group_ids = [module.security_groups.alb_security_group_id]

  # Certificate for HTTPS
  certificate_arn = module.acm_cert.alb_certificate_arn
  # Application configuration
  target_port     = 8080
  target_protocol = "HTTP"

  # Health check configuration
  health_check_path = "/api/health"

  # Dev-friendly settings
  enable_deletion_protection = false
  enable_http_redirect      = true

  tags = {
    Environment = local.environment
    Purpose     = "Development"
  }
}


#############################
# 3. ECS Module             #
#############################

module "ecs" {
  source = "../../modules/ecs"

  name_prefix       = local.prefix
  aws_region        = var.aws_region

  image_bucket_arn = module.s3_images.bucket_arn


  # Networking
  private_subnet_ids     = module.vpc.private_subnet_ids
  ecs_security_group_ids = [module.security_groups.ecs_tasks_security_group_id]
  lb_target_group_arn    = module.alb.target_group_arn
  
  # Container & Task Definition
  container_image      = "${module.ecr.repository_url}:latest"
  container_port       = 8080
  
  # Pass individual components as environment variables
  container_environment_variables = [
    {
      name  = "DOCUMENTDB_ENDPOINT"
      value = module.docdb.cluster_endpoint
    },
    {
    name  = "PAGINATION_LIMIT" 
    value = "12"
    },
    {
      name  = "DOCUMENTDB_PORT"
      value = "27017"
    },
    {
      name  = "DOCUMENTDB_USERNAME"
      value = "devadmin"
    },
    {
      name  = "AWS_IMAGES_BUCKET_NAME"
      value = module.s3_images.bucket_id
    },
  ]
  
  # Pass secrets from Secrets Manager
  container_secrets = merge({
    "DOCUMENTDB_PASSWORD" = "arn:aws:secretsmanager:eu-central-1:034362039294:secret:dev/docdb/master_password"
    "PORT" = "arn:aws:secretsmanager:eu-central-1:034362039294:secret:dev/proshop/app_secrets-aWBmop:PORT::"
    "PAYPAL_CLIENT_ID" = "arn:aws:secretsmanager:eu-central-1:034362039294:secret:dev/proshop/app_secrets-aWBmop:PAYPAL_CLIENT_ID::"
    "JWT_SECRET" = "arn:aws:secretsmanager:eu-central-1:034362039294:secret:dev/proshop/app_secrets-aWBmop:JWT_SECRET::"
    "ENV" = "arn:aws:secretsmanager:eu-central-1:034362039294:secret:dev/proshop/app_secrets-aWBmop:ENV::"
  }, {
      # This is our newly added secret!
      # The key "ADMIN_CREDENTIALS" will become the environment variable name.
      "ADMIN_CREDENTIALS" = "arn:aws:secretsmanager:eu-central-1:034362039294:secret:prod/credentials/proshop-EzZIV4"
    })
  
  
  # Dev-specific service configuration
  desired_count      = 1
  enable_autoscaling = false

  tags = {
    Environment = local.environment
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
    environment     = local.environment
    vpc_id          = module.vpc.vpc_id
    public_subnets  = length(module.vpc.public_subnet_ids)
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

output "ecr_repository_url" {
  description = "The URL of the ECR repository"
  value       = module.ecr.repository_url
}
# Add this new output block to your existing outputs
output "docdb_cluster_endpoint" {
  description = "The connection endpoint for the DocumentDB cluster."
  value       = module.docdb.cluster_endpoint
  sensitive   = true # The endpoint reveals infrastructure details
}

output "alb_info" {
  description = "Application Load Balancer information"
  value = module.alb.load_balancer_info
}

output "alb_dns_name" {
  description = "ALB DNS name for backend integration"
  value = module.alb.alb_dns_name
}

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

