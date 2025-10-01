# GitHub Actions OIDC Setup

### What It Does

Configures AWS to trust GitHub Actions as an identity provider (IdP), enabling the CI/CD pipeline to directly assume an IAM Role without requiring long-lived access keys.

- OIDC Provider Trust: Registers the GitHub Actions OIDC provider (`aws_iam_openid_connect_provider.github_actions`), telling AWS to trust tokens issued by token.actions.githubusercontent.com.
- Role Creation: Creates the GitHubActions-blue-green-infra IAM Role (`aws_iam_role.github_actions`) that GitHub Actions will assume.
- Trust Policy Condition: The Role's Trust Policy is configured to only allow assumption if:
  - The token is issued by the correct OIDC provider.
  - The request originates from the specific GitHub repository (`repo:Oksenss/3-tier-webapp-full-infra`).

🛑 Security Warning: Principle of Least Privilege
Currently, the configuration attaches the highly permissive AdministratorAccess policy to the GitHub Actions IAM Role (`aws_iam_role_policy_attachment.github_actions_admin_policy`).

For a real-world production environment, this is highly discouraged.

While this approach simplifies the initial setup, best practices dictate that you must significantly narrow the scope of this role's permissions to grant access only to the specific AWS services, actions, and resources necessary for the CI/CD pipeline to deploy the infrastructure (e.g., S3, ECS, CloudFront, etc.). Failing to do so violates the fundamental Principle of Least Privilege (PoLP) and exposes your entire AWS account to risk if the GitHub repository were ever compromised.
