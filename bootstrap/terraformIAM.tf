
# create IAM role for the Terraform pipeline with OIDC trust relationship
resource "aws_iam_role" "terraform_role" {
  name = "${var.oidc_terraform_role_name}-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.main.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          },
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_username}/${var.github_repo_name}:*" # Allow role assumption from GitHub Actions workflows triggered by tags, enabling deployment from tagged releases while maintaining security by restricting access to the specific repository
          }


        }
      }

    ]

  })

  tags = {
    Name        = "${var.oidc_terraform_role_name}-${var.environment}"
    environment = var.environment
  }
}

# attach AWS managed PowerUserAccess policy to the Terraform pipeline role for broad permissions to manage AWS resources, while the custom policy defined below will further restrict permissions to only what is necessary for Terraform operations, following the principle of least privilege in AWS IAM role design for CI/CD pipelines using OIDC with GitHub Actions
resource "aws_iam_role_policy_attachment" "github_actions_policy_attachment" {
  role       = aws_iam_role.terraform_role.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}


# create custom IAM policy for the Terraform pipeline to allow management of IAM roles and policies, which is necessary for Terraform to create and manage the IAM resources defined in the infrastructure code, while ensuring that permissions are scoped appropriately to maintain security best practices in AWS IAM when using OIDC with GitHub Actions for CI/CD pipelines
resource "aws_iam_role_policy" "terraform_pipeline_custom_policy" {
  name = "terraform-pipeline-custom-policy-${var.environment}"
  role = aws_iam_role.terraform_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:GetRole",
          "iam:UpdateRole",
          "iam:TagRole",
          "iam:UntagRole",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:GetRolePolicy",
          "iam:PassRole",
          "iam:CreatePolicy",
          "iam:DeletePolicy",
          "iam:GetPolicy",
          "iam:GetPolicyVersion",
          "iam:ListPolicyVersions",
          "iam:CreatePolicyVersion",
          "iam:DeletePolicyVersion",
          "iam:CreateOpenIDConnectProvider",
          "iam:DeleteOpenIDConnectProvider",
          "iam:GetOpenIDConnectProvider",
          "iam:TagOpenIDConnectProvider"
        ]

        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:*"
    }]
  })
}