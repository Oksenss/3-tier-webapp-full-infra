# VPC Module

### What It Does

Deploys the foundational AWS VPC network infrastructure. This includes:

- The VPC (`aws_vpc.main`). <br>
- An Internet Gateway (`aws_internet_gateway.main`).<br>
- Paired Public and Private subnets across multiple Availability Zones, based on input variables (`var.public_subnet_cidrs, var.private_subnet_cidrs, var.availability_zones`). <br>
- Required routing (Public subnets route to IGW; Private subnets are isolated).
