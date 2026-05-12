## Variables for VPC module

# Variable for the VPC ID
variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

# Variable for the environment name
variable "environment" {
  description = "The environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

# Variable for private application subnet IDs
variable "private_app_subnet_ids" {
  description = "List of IDs for private application subnets"
  type        = list(string)
}

# variable for of the interface endpoints security group ID
variable "vpc_endpoints_sg_id" {
  description = "The ID of the security group for the VPC endpoints"
  type        = string
}

# variable for the AWS region
variable "aws_region" {
  description = "The AWS region"
  type        = string
}
