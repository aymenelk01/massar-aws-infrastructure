# variable of the the environment name
variable "environment" {
    description = "The environment name (e.g., dev, staging, prod)"
    type = string
}

# variable of the vpc id
variable "vpc_id" {
    description = "The ID of the VPC"
    type = string
}

# variable of the security group for the ALB
variable "alb_sg_id" {
    description = "The ID of the security group for the ALB"
    type = string
}

# variable of the public subnet ids
variable "public_subnet_ids" {
    description = "List of public subnet IDs"
    type = list(string)
}   

# variable of the bucket name for log files
variable "logs_bucket_name" {
    description = "The name of the S3 bucket to create for log files"
    type = string
}

variable "certificate_arn" {
    description = "The ARN of the SSL certificate to create for the ALB"
    type = string
}