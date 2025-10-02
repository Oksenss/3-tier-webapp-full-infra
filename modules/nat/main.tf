#########################################################
# Local values for naming and configuration            #
#########################################################

locals {
    # Determine how many NAT gateways to create 
    nat_gateway_count = var.single_nat_gateway ? 1 : length(var.public_subnet_ids)

    # Common tags 
    common_tags = merge(
        var.tags, 
        {
            Environment = var.environment
            ManagedBy   = "Terraform"
        }
    )
}

#########################################################
# Elastic IPs for NAT Gateways                         #
#########################################################


resource "aws_eip" "nat" {
    count = local.nat_gateway_count
    domain = "vpc"

    tags = merge(
        local.common_tags,
        {
            Name = "${var.environment}-nat-eip-${count.index + 1}"
        }
    )

    depends_on = [ var.vpc_id ]
}

#########################################################
# NAT Gateways                                          #
#########################################################

resource "aws_nat_gateway" "main" {
    count = local.nat_gateway_count
    allocation_id = aws_eip.nat[count.index].id  
    subnet_id = var.public_subnet_ids[count.index]

    tags = merge(
        local.common_tags,
        {
            Name = "${var.environment}-nat-gateway-${count.index + 1}"
        }
    )
}


#########################################################
# AWS Route for NAT Gateway                             #
#########################################################

resource "aws_route" "private_nat_gateway_route" {
  # We loop through each private route table passed in.
  count = length(var.private_route_table_ids)

  route_table_id         = var.private_route_table_ids[count.index]
  destination_cidr_block = "0.0.0.0/0"

  # This logic correctly points all private route tables to the single NAT GW
  # if single_nat_gateway is true.
  nat_gateway_id = aws_nat_gateway.main[var.single_nat_gateway ? 0 : count.index].id
}
