# VPC outputs
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "internet_gateway_id" {
  description = "The ID of the Internet Gateway"
  value       = module.vpc.internet_gateway_id
}

output "nat_gateway_ids" {
  description = "The IDs of the NAT Gateways"
  value       = module.vpc.nat_gateway_id
}

output "nat_eip_ids" {
  description = "The IDs of the NAT Elastic IPs"
  value       = module.vpc.nat_eip_id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_app_subnet_ids" {
  description = "List of private application subnet IDs"
  value       = module.vpc.private_app_subnet_ids
}

output "private_db_subnet_ids" {
  description = "List of private database subnet IDs"
  value       = module.vpc.private_db_subnet_ids
}

output "availability_zones" {
  description = "List of availability zones"
  value       = module.vpc.availability_zones
}

output "public_route_table_id" {
  description = "The ID of the public route table"
  value       = module.vpc.public_route_table_id
}

output "app_route_table_ids" {
  description = "The IDs of the app route tables"
  value       = module.vpc.app_route_table_id
}

output "db_route_table_id" {
  description = "The ID of the DB route table"
  value       = module.vpc.db_route_table_id
}

# Security Group outputs
output "alb_sg_id" {
  description = "The ID of the ALB security group"
  value       = module.security.alb_sg_id
}

output "ec2_sg_id" {
  description = "The ID of the EC2 security group"
  value       = module.security.ec2_sg_id
}

output "rds_sg_id" {
  description = "The ID of the RDS security group"
  value       = module.security.rds_sg_id
}

# Compute outputs
output "alb_dns_name" {
  description = "The DNS name of the ALB"
  value       = module.compute.alb_dns_name
}

output "alb_arn" {
  description = "The ARN of the ALB"
  value       = module.compute.alb_arn
}

output "ec2_launch_template_id" {
  description = "The ID of the EC2 launch template"
  value       = module.compute.launch_template_id
}

output "target_group_arn" {
  description = "The ARN of the target group for the ALB"
  value       = module.compute.target_group_arn
}

output "asg_id" {
  description = "The ID of the auto scaling group for the EC2 instances"
  value       = module.compute.asg_id
}

# Database outputs
output "db_instance_endpoint" {
  description = "The endpoint of the RDS instance"
  value       = module.database.db_instance_endpoint
}

output "db_instance_id" {
  description = "The ID of the RDS instance"
  value       = module.database.db_instance_id
}

# Storage outputs 
output "static_bucket_name" {
  description = "The name of the S3 bucket for static files"
  value       = module.storage.static_bucket_name
}

output "state_bucket_name" {
  description = "The name of the S3 bucket for state files"
  value       = module.storage.state_bucket_name
}

output "logs_bucket_name" {
  description = "The name of the S3 bucket for log files"
  value       = module.storage.logs_bucket_name
}

output "static_bucket_regional_domain_name" {
  description = "The regional domain name of the S3 bucket for static files"
  value       = module.storage.static_bucket_regional_domain_name
}

output "aws_cloudfront_distribution_id" {
  description = "The ID of the CloudFront distribution"
  value = module.cloudfront.cloudfront_distribution_id
}

output "cloudfront_domain_name" {
  description = "The domain name of the CloudFront distribution"
  value = module.cloudfront.cloudfront_domain_name
}
