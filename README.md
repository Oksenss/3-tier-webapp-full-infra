# Multi-environment infra project for deploying MERN stack e-commerce app

## What is this project?

This project demonstrates a production-ready Multi-AZ infrastructure setup for a MERN e-commerce app using Terraform and AWS. It supports multi-environment deployments (dev/prod), blue-green deployments, and GitHub Actions CI/CD with OIDC authentication

![Architecture Diagram](multi-az-aws-infra.png)

## Tech stack

- React
- Node.js
- MongoDB
- Express.js
- Terraform
- Docker
- AWS
- GitHub Actions

## Features

### Frontend

- Written in React.js with Redux for state management.

### Backend

- Written in Node.js with Express.js framework.

### Payment Integration:

- Paypal: App allows to pay via paypal or credit card

### Modules folder

- Contains terraform modules for reusable infrastructure components.
- Each module is designed to handle specific resources like VPC, S3, ECS etc.
- Modules can be easily integrated into different environments.
- Promotes code reusability and maintainability.

### Environments folder

- Contains separate folders for each environment (dev, prod).
- Each environment folder uses the modules to create the required infrastructure.
- For storing current state of infrastructure, terraform remote state is used with S3 backend which also provides state locking functionality
- Supports scalability by allowing easy addition of new resources or modification of existing ones.
- Enhances collaboration among team members by providing a clear structure for environment management.

### OIDC folder

- Contains configurations for setting up OpenID Connect (OIDC) authentication.
- Enables secure access to AWS resources using GitHub Actions.
- Facilitates automated deployments by integrating with CI/CD pipelines.
- Improves security by eliminating the need for long-lived AWS credentials.

### .github/workflows folder

- Contains GitHub Actions workflows for automating infrastructure deployment.
- Workflows are triggered on push events to specific branches (e.g., main for production, dev for development).
- Automates the process of deploying new versions of the application with zero downtime using blue-green deployment strategy.
- Ensures consistent and repeatable deployments across different environments.

## Setup Instructions

### Environment variables (for local environment)

.env and add the following

- ENV = DEV
- PORT = 8080
- MONGO_URI = your mongodb uri
- JWT_SECRET = 'abcd1234'
- PAYPAL_CLIENT_ID = your paypal client id
- PAGINATION_LIMIT = 8

#### Paypal Setup

- Go to https://developer.paypal.com/dashboard/applications/sandbox
- Create a new app (add name, select type merchant and your business sandbox account)
- After creating the app you will see your sandbox client id which you can copy and use in your envs

#### Install Dependencies (frontend)

cd frontend <br>
npm install <br>
npm run start

#### Install Dependencies (backend)

cd backend <br>
npm install <br>
npm run server

### Environment variables (for aws)

#### AWS Secrets Manager is used to store sensitive information like database credentials, API keys, etc. Ensure that the necessary secrets are created in AWS Secrets Manager for both dev and prod aws environments.

#### Dev Environment Secrets

For this project i created has 5 separate secrets <br>
Every secret type is "Other type of secret" in AWS Secrets Manager

**NOTE**: ENV variable is used to differentiate between mongodb for local development and DocumentDB for aws development. Thats why its set to PROD in both aws envs.

Dev secrets

- dev/docdb/master_password - contains the master password for the DocumentDB cluster. (enter plain text)
- dev/proshop/app_secrets - contains these values (key value pair format)
  - PORT = 8080
  - JWT = abcd1234
  - PAGINATION_LIMIT = 8
  - PAYPAL_CLIENT_ID = your paypal client id
  - ENV = PROD

Prod secrets

- prod/docdb/master_password - contains the master password for the DocumentDB cluster. (enter plain text)
- prod/proshop/app_secrets - contains these values (key value pair format)
  - PORT = 8080
  - JWT = abcd1234
  - PAGINATION_LIMIT = 8
  - PAYPAL_CLIENT_ID = your paypal client id
  - ENV = PROD

Used for both envs though can be split into two if needed (used for creating admin user in the app)

- prod/credentials/proshop (key value pair format)
  - email = admin@email.com
  - password = admin123

### Creating S3 bucket

Creating s3 bucket is necessary for terraform state management and state locking. You can choose default options with enabled versioning

Make sure this bucket exists before running `terraform init` in any environment

To be continued
