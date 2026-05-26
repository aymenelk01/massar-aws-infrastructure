terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Default provider — eu-south-1
provider "aws" {
  region = var.aws_region
}

# Second provider — us-east-1 for WAF and ACM (CloudFront requirements)
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}