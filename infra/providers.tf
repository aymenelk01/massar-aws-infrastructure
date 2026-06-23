terraform {
  required_version = ">= 1.15.4"

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

  default_tags {
    tags = {
      Environment = var.environment == "dev" ? "Dev" : (var.environment == "staging" ? "Stage" : (var.environment == "prod" ? "Prod" : var.environment))
      Project     = "Massar"
      ManagedBy   = "Terraform"
      Service     = var.service
    }
  }
}

# Second provider — us-east-1 for WAF and ACM (CloudFront requirements)
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = {
      Environment = var.environment == "dev" ? "Dev" : (var.environment == "staging" ? "Stage" : (var.environment == "prod" ? "Prod" : var.environment))
      Project     = "Massar"
      ManagedBy   = "Terraform"
      Service     = var.service
    }
  }
}
