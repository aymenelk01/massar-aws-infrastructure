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