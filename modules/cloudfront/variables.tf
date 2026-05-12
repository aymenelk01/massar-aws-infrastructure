

# Variable of the static bucket regional domain name
variable "static_bucket_regional_domain_name" {
  description = "The regional domain name of the S3 bucket for static files"
  type        = string
}

# variable of the static bucket ARN
variable "static_bucket_arn" {
  description = "The ARN of the S3 bucket for static files"
  type        = string
}   

# variable of the static bucket id
variable "static_bucket_id" {
  description = "The ID of the S3 bucket for static files"
  type        = string
  
}

# variable of the dns name of the ALB
variable "alb_dns_name" {
  description = "The DNS name of the ALB"
  type        = string
}

# variable of the envrionment name
variable "environment" {
  description = "The environment name (e.g., dev, staging, prod)"
  type        = string
}

# variable for the AWS region
variable "aws_region" {
  description = "The AWS region"
  type        = string
}