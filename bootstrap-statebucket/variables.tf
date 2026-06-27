variable "environment" {
  description = "The environment for which to create the resources (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

# variable for the bucket name for state files
variable "state_bucket_name" {
  description = "The name of the S3 bucket to create for state files"
  type        = string
  default     = "dev-app-massar-state"
}

variable "aws_region" {
  description = "The AWS region where the resources will be created"
  type        = string
  default     = "eu-south-1"
}

variable "service" {
  description = "The service name for FinOps tagging"
  type        = string
  default     = "Massar"
}

