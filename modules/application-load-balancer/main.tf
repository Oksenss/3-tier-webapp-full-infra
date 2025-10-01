#########################################################
# Local values                                         #
#########################################################

locals {
  alb_name = "${var.name_prefix}-alb"
  target_group_name_blue = "${var.name_prefix}-blue-tg"
  target_group_name_green = "${var.name_prefix}-green-tg"

  target_group_name_single = "${var.name_prefix}-app-tg"
  
  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      Module      = "application-load-balancer"
    }
  )
}

#########################################################
# Application Load Balancer                            #
#########################################################

resource "aws_lb" "main" {
  name               = local.alb_name
  internal           = false  # Internet-facing
  load_balancer_type = "application"

  # Security and Networking
  security_groups = var.security_group_ids
  subnets        = var.public_subnet_ids

  # Configuration
  enable_deletion_protection     = var.enable_deletion_protection
  idle_timeout                  = var.idle_timeout
  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing

  tags = merge(
    local.common_tags,
    {
      Name = local.alb_name
    }
  )
}

#########################################################
# Target Group  (Blue/Green or Single)                  #
#########################################################
resource "aws_lb_target_group" "app_blue" {
  ### MODIFIED ###
  count = var.enable_blue_green ? 1 : 0 

  name                   = local.target_group_name_blue
  port                   = var.target_port
  protocol               = var.target_protocol
  vpc_id                 = var.vpc_id
  target_type            = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = var.health_check_healthy_threshold
    unhealthy_threshold = var.health_check_unhealthy_threshold
    timeout             = var.health_check_timeout
    interval            = var.health_check_interval
    path                = var.health_check_path
    matcher             = var.health_check_matcher
  }

  deregistration_delay = 30
  tags = merge(local.common_tags, { Name = local.target_group_name_blue })
  lifecycle { create_before_destroy = true }
}


resource "aws_lb_target_group" "app_green" {
  ### MODIFIED ###
  count = var.enable_blue_green ? 1 : 0

  name                   = local.target_group_name_green
  port                   = var.target_port
  protocol               = var.target_protocol
  vpc_id                 = var.vpc_id
  target_type            = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = var.health_check_healthy_threshold
    unhealthy_threshold = var.health_check_unhealthy_threshold
    timeout             = var.health_check_timeout
    interval            = var.health_check_interval
    path                = var.health_check_path
    matcher             = var.health_check_matcher
  }
  
  deregistration_delay = 30
  tags = merge(local.common_tags, { Name = local.target_group_name_green })
  lifecycle { create_before_destroy = true }
}



resource "aws_lb_target_group" "app_single" {

  ### MODIFIED ###
  # This resource is for non-blue-green deployments like 'dev'
  count = var.enable_blue_green ? 0 : 1


  name        = local.target_group_name_single
  port        = var.target_port
  protocol    = var.target_protocol
  vpc_id      = var.vpc_id
  target_type = "ip"  # Required for Fargate

  health_check {
    enabled             = true
    healthy_threshold   = var.health_check_healthy_threshold
    unhealthy_threshold = var.health_check_unhealthy_threshold
    timeout             = var.health_check_timeout
    interval            = var.health_check_interval
    path                = var.health_check_path
    matcher             = var.health_check_matcher
    port                = "traffic-port"
    protocol            = var.target_protocol
  }

  # Ensure proper deregistration
  deregistration_delay = 30

  tags = merge(
    local.common_tags,
    {
      Name = local.target_group_name_single
    }
  )

  # Allow target group to be recreated if needed
  lifecycle {
    create_before_destroy = true
  }
}



#########################################################
# HTTPS Listener                                       #
#########################################################
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    ### MODIFIED ###
    # Point to the blue TG in a blue/green setup, otherwise point to the single TG
    target_group_arn = var.enable_blue_green ? aws_lb_target_group.app_blue[0].arn : aws_lb_target_group.app_single[0].arn
  }

  tags = local.common_tags
}

### NEW - Test Listener for Green Deployment ###
resource "aws_lb_listener" "https_test" {
  count = var.enable_blue_green ? 1 : 0

  load_balancer_arn = aws_lb.main.arn
  port              = var.test_listener_port
  protocol          = "HTTPS"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    # This listener ALWAYS points to the green target group
    target_group_arn = aws_lb_target_group.app_green[0].arn
  }

  tags = merge(local.common_tags, {Name = "${local.alb_name}-test-listener"})
}


#########################################################
# HTTP Redirect Listener (Optional)                    #
#########################################################

resource "aws_lb_listener" "http_redirect" {
  count = var.enable_http_redirect ? 1 : 0

  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags = local.common_tags
}