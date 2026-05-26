resource "aws_iam_openid_connect_provider" "main" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  tags = {
    Name = "github-actions-oidc-provider"
  }

}

data "aws_caller_identity" "current" {}


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
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_username}/${var.github_repo_name}:ref:refs/heads/${var.github_branch_name}" # Restrict the role assumption to a specific GitHub repository and branch for enhanced security, ensuring that only workflows from the specified repository and branch can assume this role, which is a best practice for least privilege access control in AWS IAM when using OIDC with GitHub Actions
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

resource "aws_iam_role_policy_attachment" "github_actions_policy_attachment" {
  role       = aws_iam_role.terraform_role.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

resource "aws_iam_role_policy" "github_actions_custom_policy" {
  name = "github-actions-custom-policy-${var.environment}"
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









resource "aws_iam_role" "deploy_role" {
  name = "${var.oidc_deploy_role_name}-${var.environment}"

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
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_username}/${var.github_repo_name}:ref:refs/heads/${var.github_branch_name}" # Restrict the role assumption to a specific GitHub repository and branch for enhanced security, ensuring that only workflows from the specified repository and branch can assume this role, which is a best practice for least privilege access control in AWS IAM when using OIDC with GitHub Actions
          }
        }
      }

    ]

  })

  tags = {
    Name        = "${var.oidc_deploy_role_name}-${var.environment}"
    environment = var.environment
  }
}

resource "aws_iam_role_policy" "deploy_custom_policy" {
  name = "github-actions-custom-policy-${var.environment}"
  role = aws_iam_role.deploy_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [

      # S3 Access - scoped to the static bucket only
      {
        sid    = "S3StaticBucketAccess"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ]
        Resource = "arn:aws:s3:::${var.static_bucket_name}/*"
      },
      {
        sid    = "S3StaticBucketList"
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = "arn:aws:s3:::${var.static_bucket_name}"
      },

      #ECR Authentication - must be * (account-level action, cannot be scoped to a single repo)
      {
        sid    = "ECRAuthorizationToken"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },

      # ECR Push - scoped to Massar ECR repository only
      {
        sid    = "ECRPull"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ]
        Resource = "${var.ecr_repository_arn}"
      },

      # ECS Service Management - scoped to Massar service ARN
      {
        sid    = "ECSDeploy"
        Effect = "Allow"
        Action = [
          "ecs:UpdateService",
          "ecs:DescribeServices"
        ]
        Resource = [
          "${var.ecs_service_arn}"
        ]
      },

      # ECS Task Definition Management - must be * due to AWS IAM API design
      {
        sid    = "ECSDeployRegisterTaskDefinition"
        Effect = "Allow"
        Action = [
          "ecs:DescribeTaskDefinition",
          "ecs:RegisterTaskDefinition"
        ]
        Resource = "*"
      },

      # IAM PassRole - scoped to the ECS task execution role only
      {
        sid    = "PassRole"
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = [
          "${var.iam_role_execution_arn}",
          "${var.iam_role_task_arn}"
        ]
      }
    ]
  })
}

