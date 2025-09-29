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
# NOTE: This resource is unique per AWS account. We will import the existing one.
resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  # MODIFIED: Updated to the latest thumbprints recommended by AWS.
  # Terraform will automatically pick the one that matches.
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]
}

# IAM Role for GitHub Actions
resource "aws_iam_role" "github_actions" {
  # MODIFIED: Made the role name unique to this project.
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
            # This correctly targets your blue-green repo
            "token.actions.githubusercontent.com:sub" = "repo:Oksenss/blue-green:*"
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