output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  value       = aws_nat_gateway.main[*].id
}

output "elastic_ip_ids" {
  description = "List of Elastic IP IDs for NAT Gateways"
  value       = aws_eip.nat[*].id
}

output "elastic_ip_addresses" {
  description = "List of Elastic IP addresses for NAT Gateways"
  value       = aws_eip.nat[*].public_ip
}

# output "route_table_ids" {
#   description = "List of private route table IDs"
#   value       = aws_route_table.private[*].id
# }

output "nat_gateway_count" {
  description = "Number of NAT Gateways created"
  value       = local.nat_gateway_count
}