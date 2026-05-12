## Variables for VPC module

# Variable for the environment name
variable "environment" {
    description = "The environment name (e.g., dev, staging, prod)"
    type = string
    default = "dev"
}

# Variable for VPC CIDR block
variable "vpc_cidr" {
    description = "CIDR block for the VPC"
    type = string
    default = "10.0.0.0/16"
  
}

# Variable for the availability zones
variable "availability_zones" {
    description = "List of availability zones"
    type = list(string)
    default = ["eu-south-1a", "eu-south-1b", "eu-south-1c"]
}

# Variable for public subnet CIDR blocks
variable "public_subnet_cidrs" {
    description = "List of CIDR blocks for public subnets"
    type = list(string)
    default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

# Variable for private application subnet CIDR blocks
variable "private_app_subnet_cidrs" {
    description = "List of CIDR blocks for private application subnets"
    type = list(string)
    default = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
}

# Variable for private database subnet CIDR blocks
variable "private_db_subnet_cidrs" {
    description = "List of CIDR blocks for private database subnets"
    type = list(string)
    default = ["10.0.20.0/24", "10.0.21.0/24", "10.0.22.0/24"]
}

# variable for the AWS region
variable "aws_region" {
    description = "The AWS region"
    type = string
}
