# variable for the environment name
variable "environment" {
  description = "The environment name (e.g., dev, staging, prod)"
  type        = string
}

# variable for the AWS region
variable "aws_region" {
  description = "The AWS region"
  type        = string
}

# variable of the database name
variable "db_name" {
  description = "The name of the database"
  type        = string
}

# variable of the database username for the RDS instance
variable "db_username" {
  description = "The database username for the RDS instance"
  type        = string
}

# variable of the database password for the RDS instance
variable "db_password" {
  description = "The database password for the RDS instance"
  type        = string
  sensitive   = true
}

# variable of the bucket name
variable "documents_bucket_name" {
  description = "The name of the S3 bucket to create for documents"
  default     = "documents_bucket_dev"
  type        = string
}

# variable of the bucket name
variable "static_bucket_name" {
  description = "The name of the S3 bucket to create for static files"
  type        = string
}

# variable for the bucket name for state files
variable "state_bucket_name" {
  description = "The name of the S3 bucket to create for state files"
  type        = string
}

# variable for the log bucket name
variable "logs_bucket_name" {
  description = "The name of the S3 bucket to create for log files"
  type        = string
}

variable "cloudfront_prefix_list_id" {
  description = "The ID of the AWS-managed prefix list for CloudFront"
  type        = string
}

variable "certificate_arn" {
  description = "The ARN of the SSL certificate to create for the ALB"
  type        = string
}

variable "oidc_terraform_role_name" {
  description = "The name of the IAM role to create for GitHub Actions OIDC authentication"
  type        = string
}

variable "oidc_deploy_role_name" {
  description = "The name of the IAM role to create for GitHub Actions OIDC authentication"
  type        = string
}

variable "github_repo_name" {
  description = "The name of the GitHub repository (e.g., aymenelk01/massar-aws-infrastructure)"
  type        = string
}

variable "github_username" {
  description = "The GitHub username for the repository (e.g., aymenelk01)"
  type        = string
}
