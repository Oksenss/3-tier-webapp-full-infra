#########################################################
# Local values                                         #
#########################################################

locals {
  common_tags = merge(
    var.tags, 
    {
        Environment = var.environment
        Module      = "security-groups"
    }
  )
}

#########################################################
# Application Load Balancer Security Group             #
#########################################################

resource "aws_security_group" "alb" {
  name        = "${var.environment}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = var.vpc_id

  # HTTPS ingress
  ingress {
    description      = "HTTPS from the Internet"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = var.allowed_cidr_blocks
    ipv6_cidr_blocks = var.allowed_ipv6_cidr_blocks
  }

  # HTTP ingress (conditional)
  dynamic "ingress" {
    for_each = var.enable_http ? [1] : []
    content {
      description      = "HTTP from the Internet"
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = var.allowed_cidr_blocks
      ipv6_cidr_blocks = var.allowed_ipv6_cidr_blocks
    }
  }

  # Additional ports (if any)
  dynamic "ingress" {
    for_each = var.additional_alb_ports
    content {
      description      = ingress.value.description
      from_port        = ingress.value.port
      to_port          = ingress.value.port
      protocol         = ingress.value.protocol
      cidr_blocks      = var.allowed_cidr_blocks
      ipv6_cidr_blocks = var.allowed_ipv6_cidr_blocks
    }
  }

  # Allow all outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${var.environment}-alb-sg"
      Type = "alb"
    }
  )
}


#########################################################
# ECS Tasks Security Group                             #
#########################################################

resource "aws_security_group" "ecs_tasks" {
  name        = "${var.environment}-ecs-tasks-sg"
  description = "Security group for ECS tasks (backend application)"
  vpc_id      = var.vpc_id

  # Allow traffic from ALB
  ingress {
    description     = "Traffic from ALB"
    from_port       = var.application_port
    to_port         = var.application_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # Additional ingress rules (if any)
  dynamic "ingress" {
    for_each = var.additional_ecs_ingress
    content {
      description     = ingress.value.description
      from_port       = ingress.value.port
      to_port         = ingress.value.port
      protocol        = ingress.value.protocol
      security_groups = ingress.value.source_sg_ids
      cidr_blocks     = ingress.value.cidr_blocks
    }
  }

  # Allow all outbound traffic (for API calls, package downloads, etc.)
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${var.environment}-ecs-tasks-sg"
      Type = "ecs"
    }
  )
}


#########################################################
# DocumentDB Security Group                            #
#########################################################

resource "aws_security_group" "docdb" {
  name        = "${var.environment}-docdb-sg"
  description = "Security group for DocumentDB cluster"
  vpc_id      = var.vpc_id

  # Allow traffic from ECS tasks only
  ingress {
    description     = "DocumentDB/MongoDB from ECS"
    from_port       = var.database_port
    to_port         = var.database_port
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  # Minimal outbound access (DocumentDB typically doesn't need outbound)
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${var.environment}-docdb-sg"
      Type = "database"
    }
  )
}
