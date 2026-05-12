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

