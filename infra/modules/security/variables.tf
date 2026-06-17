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

variable "vpc_cidr_block" {
    description = "The CIDR block of the VPC"
    type = string
}