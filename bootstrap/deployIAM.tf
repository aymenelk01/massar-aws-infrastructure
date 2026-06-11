# This Terraform configuration defines an AWS IAM role and policy for a deployment pipeline that integrates with GitHub Actions using OpenID Connect (OIDC) for secure authentication. The role allows GitHub Actions workflows to assume it and perform specific actions on AWS resources, such as S3, ECR, and ECS, while adhering to the principle of least privilege by restricting permissions to only what is necessary for the deployment process.

# create IAM role for the deployment pipeline with OIDC trust relationship
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
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_username}/${var.github_app_repo_name}:ref:refs/heads/${var.github_branch_name}" # Restrict the role assumption to a specific GitHub repository and branch for enhanced security, ensuring that only workflows from the specified repository and branch can assume this role, which is a best practice for least privilege access control in AWS IAM when using OIDC with GitHub Actions
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

# create custom IAM policy for the deployment pipeline with least privilege permissions and attach it to the deploy role
resource "aws_iam_role_policy" "deploy_custom_policy" {
  name = "deploy-pipeline-custom-policy-${var.environment}"
  role = aws_iam_role.deploy_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [

      # S3 Access - scoped to the static bucket only
      {
        Sid    = "S3StaticBucketAccess"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ]
        Resource = "arn:aws:s3:::${var.environment}-${var.static_bucket_name}/*"
      },
      {
        Sid    = "S3StaticBucketList"
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = "arn:aws:s3:::${var.environment}-${var.static_bucket_name}"
      },

      #ECR Authentication - must be * (account-level action, cannot be scoped to a single repo)
      {
        Sid    = "ECRAuthorizationToken"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },

      # ECR Push - scoped to Massar ECR repository only
      {
        Sid    = "ECRPull"
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
        Resource = "arn:aws:ecr:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:repository/ecr-repository-${var.environment}"
      },

      # ECS Service Management - scoped to Massar service ARN
      {
        Sid    = "ECSDeploy"
        Effect = "Allow"
        Action = [
          "ecs:UpdateService",
          "ecs:DescribeServices"
        ]
        Resource = [
          "arn:aws:ecs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:service/${var.environment}-cluster/${var.environment}-service"
        ]
      },

      # ECS Task Definition Management - must be * due to AWS IAM API design
      {
        Sid    = "ECSDeployRegisterTaskDefinition"
        Effect = "Allow"
        Action = [
          "ecs:DescribeTaskDefinition",
          "ecs:RegisterTaskDefinition"
        ]
        Resource = "*"
      },

      # IAM PassRole - scoped to the ECS task execution role only
      {
        Sid    = "PassRole"
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ecsRole-${var.environment}",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ecsTaskRole-${var.environment}"
        ]
      },

       # SSM Parameter Store Read Access - scoped to the specific parameters for the application
      {
        Sid    = "SSMReadCognitoParameters"
        Effect = "Allow"
        Action = ["ssm:GetParameter"]
        Resource = ["arn:aws:ssm:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:parameter/massar/${var.environment}/cognito_user_pool_id",
          "arn:aws:ssm:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:parameter/massar/${var.environment}/cognito_client_id"
        ]
      }
    ]
  })
}

