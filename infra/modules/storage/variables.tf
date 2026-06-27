variable "environment" {
  description = "The environment for which to create the resources (e.g., dev, staging, prod)"
  type        = string
}

# variable of the bucket name
variable "documents_bucket_name" {
  description = "The name of the S3 bucket to create for documents"
  type        = string
}

# variable of the bucket name
variable "static_bucket_name" {
  description = "The name of the S3 bucket to create for static files"
  type        = string
}

# variable for the log bucket name
variable "logs_bucket_name" {
  description = "The name of the S3 bucket to create for log files"
  type        = string
}
