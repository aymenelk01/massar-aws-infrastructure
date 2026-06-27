# VPC outputs
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
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

# Security Group outputs
output "alb_sg_id" {
  description = "The ID of the ALB security group"
  value       = module.security.alb_sg_id
}

output "ecs_sg_id" {
  description = "The ID of the ECS security group"
  value       = module.security.ecs_sg_id
}

# ECR outputs
output "ecr_repository_url" {
  description = "The URL of the ECR repository"
  value       = module.ecr.ecr_repository_url
}

output "ecr_flyway_repository_url" {
  description = "The URL of the ECR repository for Flyway"
  value       = module.ecr.ecr_flyway_repository_url

}

# alb outputs
output "alb_dns_name" {
  description = "The DNS name of the ALB"
  value       = module.loadbalancer.alb_dns_name
}

output "alb_arn" {
  description = "The ARN of the ALB"
  value       = module.loadbalancer.alb_arn
}

output "target_group_arn" {
  description = "The ARN of the target group for the ALB"
  value       = module.loadbalancer.target_group_arn
}


# Database outputs
output "aurora_writer_endpoint" {
  description = "The endpoint of the Aurora writer instance"
  value       = module.database.aurora_writer_endpoint
}

output "rds_proxy_writer_endpoint" {
  description = "The endpoint of the RDS Proxy writer"
  value       = module.database.rds_proxy_writer_endpoint
}

output "rds_proxy_reader_endpoint" {
  description = "The endpoint of the RDS Proxy reader"
  value       = module.database.rds_proxy_reader_endpoint
}

# Storage outputs 
output "documents_bucket_name" {
  description = "The name of the S3 bucket for documents files"
  value       = module.storage.documents_bucket_name
}

output "logs_bucket_name" {
  description = "The name of the S3 bucket for log files"
  value       = module.storage.logs_bucket_name
}

output "documents_bucket_regional_domain_name" {
  description = "The regional domain name of the S3 bucket for documents files"
  value       = module.storage.documents_bucket_regional_domain_name
}

# cloudfront outputs
output "aws_cloudfront_distribution_id" {
  description = "The ID of the CloudFront distribution"
  value       = module.cloudfront.cloudfront_distribution_id
}

output "cloudfront_domain_name" {
  description = "The domain name of the CloudFront distribution"
  value       = module.cloudfront.cloudfront_domain_name
}

# notifications outputs
output "sqs_queue_url" {
  description = "The URL of the SQS queue"
  value       = module.notifications.sqs_queue_url
}

output "sns_topic_arn" {
  description = "The ARN of the SNS topic for notifications"
  value       = module.notifications.sns_topic_arn
}

# cognito outputs
output "user_pool_id" {
  description = "The ID of the Cognito User Pool"
  value       = module.cognito.user_pool_id
}

output "user_pool_client_id" {
  description = "The ID of the Cognito User Pool Client"
  value       = module.cognito.user_pool_client_id
}

