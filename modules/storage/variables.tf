variable "environment" {
  description = "The environment for which to create the resources (e.g., dev, staging, prod)"
  type        = string
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
