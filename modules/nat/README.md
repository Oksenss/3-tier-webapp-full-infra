# NAT Gateway Module

### What It Does

Deploys Network Address Translation (NAT) Gateways to enable outbound internet access from private subnets. This module:

- Creates an Elastic IP (`aws_eip.nat`) and a NAT Gateway (`aws_nat_gateway.main`) in the specified public subnets.
- Updates all Private Route Tables (using `aws_route.private_nat_gateway_route`) to direct 0.0.0.0/0 traffic using the created NAT Gateways.
- Supports a single_nat_gateway flag to optionally deploy only one NAT Gateway for cost savings, regardless of the number of private subnets.
