variable "environment" {
    description = "The environment for which to create the resources (e.g., dev, staging, prod)"
    type        = string
}

variable "aws_region" {
    description = "The AWS region where the resources will be created"
    type        = string
}

variable "oidc_terraform_role_name" {
    description = "The name of the IAM role to create for GitHub Actions OIDC authentication"
    type        = string
}

variable "oidc_deploy_role_name" {
    description = "The name of the IAM role to create for GitHub Actions OIDC authentication"
    type        = string
}

variable "github_repo_name" {
    description = "The name of the GitHub repository (e.g., aymenelk01/massar-aws-infrastructure)"
    type        = string
}

variable "github_branch_name" {
    description = "The name of the GitHub branch (e.g., main)"
    type        = string
    default     = "main"
}

variable "github_username" {
    description = "The GitHub username for the repository (e.g., aymenelk01)"
    type        = string
}

variable "static_bucket_name" {
  description = "The name of the S3 bucket to create for static files"
  type        = string
}

