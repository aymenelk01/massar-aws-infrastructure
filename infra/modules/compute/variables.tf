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

variable "ecr_flyway_repository_url" {
  description = "The URL of the ECR repository for Flyway"
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

variable "documents_bucket_name" {
  description = "The name of the S3 bucket for documents files"
  type        = string
}

variable "sqs_queue_url" {
  description = "The URL of the SQS queue"
  type        = string
}

variable "sqs_queue_arn" {
  description = "The ARN of the SQS queue"
  type        = string
}

variable "db_iam_username" {
  description = "The username of the database"
  type        = string
  default     = "db_iam_user"
}

variable "db_password_secret_arn" {
  description = "The ARN of the database password secret"
  type        = string
}

variable "rds_proxy_resource_id" {
  description = "The resource ID of the RDS Proxy"
  type        = string
}

# variable of the AWS region
variable "aws_region" {
  description = "The AWS region"
  type        = string
}
