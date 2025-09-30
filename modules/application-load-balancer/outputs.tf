output "alb_id" {
  description = "ID of the Application Load Balancer"
  value       = aws_lb.main.id
}

output "alb_arn" {
  description = "ARN of the Application LoadBalancer"
  value       = aws_lb.main.arn
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Hosted zone ID of the Application Load Balancer"
  value       = aws_lb.main.zone_id
}

output "target_group_id" {
  description = "ID of the primary target group. For blue/green, this is the Blue TG."
  value       = var.enable_blue_green ? aws_lb_target_group.app_blue[0].id : aws_lb_target_group.app_single[0].id
}

output "target_group_arn" {
  description = "ARN of the primary target group. For blue/green, this is the Blue TG."
  value       = var.enable_blue_green ? aws_lb_target_group.app_blue[0].arn : aws_lb_target_group.app_single[0].arn
}

output "target_group_name" {
  description = "Name of the primary target group. For blue/green, this is the Blue TG."
  value       = var.enable_blue_green ? aws_lb_target_group.app_blue[0].name : aws_lb_target_group.app_single[0].name
}

output "target_group_blue_arn" {
  description = "ARN of the Blue target group."
  value       = var.enable_blue_green ? aws_lb_target_group.app_blue[0].arn : null
}

output "target_group_blue_name" {
  description = "Name of the Blue target group."
  value       = var.enable_blue_green ? aws_lb_target_group.app_blue[0].name : null
}

output "target_group_green_arn" {
  description = "ARN of the Green target group."
  value       = var.enable_blue_green ? aws_lb_target_group.app_green[0].arn : null
}

output "target_group_green_name" {
  description = "Name of the Green target group."
  value       = var.enable_blue_green ? aws_lb_target_group.app_green[0].name : null
}

output "https_listener_arn" {
  description = "ARN of the HTTPS listener"
  value       = aws_lb_listener.https.arn
}

output "test_listener_arn" {
  description = "ARN of the test HTTPS listener for green deployments."
  value       = var.enable_blue_green ? aws_lb_listener.https_test[0].arn : null
}

output "http_listener_arn" {
  description = "ARN of the HTTP redirect listener"
  value       = var.enable_http_redirect ? aws_lb_listener.http_redirect[0].arn : null
}

output "load_balancer_info" {
  description = "Complete load balancer information"
  value = {
    arn              = aws_lb.main.arn
    dns_name         = aws_lb.main.dns_name
    hosted_zone_id   = aws_lb.main.zone_id
    target_group_arn = var.enable_blue_green ? aws_lb_target_group.app_blue[0].arn : aws_lb_target_group.app_single[0].arn
    https_endpoint   = "https://${aws_lb.main.dns_name}"
  }
}