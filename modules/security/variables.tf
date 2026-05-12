# variable to receive the environment name from the vpc module
variable "environment" {
    description = "The environment name (e.g., dev, staging, prod)"
    type = string
}

# variable to receive the vpc id from the vpc module
variable "vpc_id" {
    description = "The ID of the VPC"
    type = string
}

# variable of the managed prefix list for CloudFront
variable "cloudfront_prefix_list_id" {
    description = "The ID of the AWS-managed prefix list for CloudFront"
    type = string
    default = "pl-1bbc5972"
}

