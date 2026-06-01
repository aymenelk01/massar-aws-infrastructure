output "deploy_role_arn" {
  value       = aws_iam_role.deploy_role.arn
  description = "The ARN of the IAM role for deploy OIDC authentication"
}

output "terraform_role_arn" {
  value       = aws_iam_role.terraform_role.arn
  description = "The ARN of the IAM role for Terraform OIDC authentication"
}