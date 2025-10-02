terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket       = "my-blue-green-depl-tf-state"
    key          = "tf-state-oidc"
    region       = "eu-central-1"
    use_lockfile = true
    encrypt      = true
  }
}

# Default provider → all resources go to eu-central-1 unless specified
provider "aws" {
  region = "eu-central-1"
}

# GitHub Actions OIDC Provider
resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  # Updated to the latest thumbprints recommended by AWS.
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]
}

# IAM Role for GitHub Actions
resource "aws_iam_role" "github_actions" {
  name = "GitHubActions-blue-green-infra"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_actions.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:Oksenss/3-tier-webapp-full-infra:*"
          }
        }
      }
    ]
  })
}


# Attach the AWS-managed AdministratorAccess policy to the role
# WARNING: This grants full admin permissions. For production, use a more restrictive policy.
resource "aws_iam_role_policy_attachment" "github_actions_admin_policy" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}