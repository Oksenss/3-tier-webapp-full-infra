locals {
  common_tags = merge(
    var.tags,
    {
      Module = "vpc-endpoints"
    }
  )
}

#########################################################
# S3 Gateway Endpoint                                  #
#########################################################

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"

  # Associate with the private route tables
  route_table_ids = var.private_route_table_ids

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name_prefix}-s3-gateway-endpoint"
    }
  )
}

#########################################################
# Security Group for Interface Endpoints               #
#########################################################

resource "aws_security_group" "vpc_endpoints_sg" {
  name        = "${var.name_prefix}-vpc-endpoints-sg"
  description = "Allow traffic from internal resources to VPC endpoints"
  vpc_id      = var.vpc_id

  # Allow HTTPS traffic FROM the ECS tasks security group
  ingress {
    description     = "Allow HTTPS from ECS tasks"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [var.ecs_tasks_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name_prefix}-vpc-endpoints-sg"
    }
  )
}

#########################################################
# CloudWatch Logs Interface Endpoint                   #
#########################################################

resource "aws_vpc_endpoint" "logs" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type   = "Interface"

  security_group_ids  = [aws_security_group.vpc_endpoints_sg.id]
  subnet_ids          = var.private_subnet_ids
  private_dns_enabled = true # Best practice! Allows use of standard DNS names.

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name_prefix}-logs-interface-endpoint"
    }
  )
}
