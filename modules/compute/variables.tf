# variable of the the environment name
variable "environment" {
  description = "The environment name (e.g., dev, staging, prod)"
  type        = string
}

# variable of the vpc id
variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

# variable of the private app subnet ids
variable "private_app_subnet_ids" {
  description = "List of private application subnet IDs"
  type        = list(string)
}

# variable of the dynamodb table name
variable "dynamodb_session_table_arn" {
  description = "The ARN of the DynamoDB table to create for storing application data"
  type        = string
}

# variable of the dyanamodb table of the user table
variable "dynamodb_user_table_arn" {
  description = "The ARN of the DynamoDB user table to create for storing user data"
  type        = string
}

# variable of the documents files bucket ARN
variable "documents_bucket_arn" {
  description = "The ARN of the S3 bucket to create for documents files"
  type        = string
}

variable "user_pool_id" {
  description = "The ID of the Cognito User Pool"
  type        = string
}

variable "user_pool_client_id" {
  description = "The ID of the Cognito User Pool Client"
  type        = string
}

variable "elasticache_replication_group_endpoint" {
  description = "The endpoint of the ElastiCache replication group"
  type        = string
}

variable "rds_proxy_endpoint" {
  description = "The endpoint of the RDS Proxy"
  type        = string
}
variable "db_name" {
  description = "The name of the database"
  type        = string
}

variable "ecr_repository_url" {
  description = "The URL of the ECR repository"
  type        = string
}

variable "ecs_sg_id" {
  description = "The ID of the security group for the ECS tasks"
  type        = string
}

variable "target_group_arn" {
  description = "The ARN of the target group"
  type        = string
}
# variable of the AWS region
variable "aws_region" {
  description = "The AWS region"
  type        = string
}
