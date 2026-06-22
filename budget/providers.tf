terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  required_version = ">= 1.15.4"
}

# Default provider — eu-south-1
provider "aws" {
  region = "eu-south-1"

  default_tags {
    tags = {
      Environment = var.environment
      Project     = "Massar"
      ManagedBy   = "Terraform"
      Service     = var.service
    }
  }
}
