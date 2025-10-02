# environments/

### This folder contains the complete, deployable Terraform configurations for each application lifecycle stage (dev, prod).

The goal is strict isolation combined with module reusability. Each subdirectory is a self-contained environment with its own backend state and a unique VPC CIDR range
