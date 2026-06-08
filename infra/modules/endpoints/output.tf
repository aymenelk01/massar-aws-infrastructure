# ------------------------------------------
# VPC Endpoints Outputs
# ------------------------------------------

output "vpc_endpoint_ids" {
  description = "A map of service names to their corresponding VPC Endpoint IDs."
  value       = { for service, endpoint in aws_vpc_endpoint.interfaces : service => endpoint.id }
}

output "vpc_endpoint_arns" {
  description = "A map of service names to their corresponding VPC Endpoint ARNs."
  value       = { for service, endpoint in aws_vpc_endpoint.interfaces : service => endpoint.arn }
}

output "vpc_endpoint_dns_entries" {
  description = "A map of service names to their corresponding DNS entries."
  value       = { for service, endpoint in aws_vpc_endpoint.interfaces : service => endpoint.dns_entry }
}