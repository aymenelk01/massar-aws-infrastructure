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

# variable of the database username for the RDS instance
variable "db_username" {
    description = "The database username for the RDS instance"
    type = string
}

# variable of the database password for the RDS instance
variable "db_password" {
    description = "The database password for the RDS instance"
    type = string
    sensitive = true
}

# variable of the bucket name
variable "documents_bucket_name" {
  description = "The name of the S3 bucket to create for documents"
  default = "documents_bucket_${var.environment}"
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
