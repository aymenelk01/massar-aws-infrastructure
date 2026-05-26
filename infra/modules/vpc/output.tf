### Outputs for VPC module
# Output for VPC ID
output "vpc_id" {
    description = "The ID of the VPC"
    value = aws_vpc.main.id
}
# Output for Internet Gateway ID
output "internet_gateway_id" {
    description = "The ID of the Internet Gateway"
    value = aws_internet_gateway.IGW.id
}

# Output for public subnet IDs
output "public_subnet_ids" {
    description = "List of public subnet IDs"
    value = aws_subnet.public[*].id
}
# Output for private application subnet IDs
output "private_app_subnet_ids" {
    description = "List of private application subnet IDs"
    value = aws_subnet.private_app[*].id
}
# Output for private database subnet IDs
output "private_db_subnet_ids" {
    description = "List of private database subnet IDs"
    value = aws_subnet.private_db[*].id
}
# Output for availability zones
output "availability_zones" {
    description = "List of availability zones"
    value = var.availability_zones
}
# output for public route table ID
output "public_route_table_id" {
    description = "The ID of the public route table"
    value = aws_route_table.public_RT.id
}
# Output for app route table ID
output "app_route_table_id" {
    description = "The ID of the app route table"
    value = aws_route_table.app_RT[*].id
}
# Output for db route table ID
output "db_route_table_id" {
    description = "The ID of the db route table"
    value = aws_route_table.db_RT[*].id
}

# Output for VPC endpoint ID for S3
output "s3_endpoint_id" {
    description = "The ID of the VPC endpoint for S3"
    value = aws_vpc_endpoint.s3_gateway.id
}