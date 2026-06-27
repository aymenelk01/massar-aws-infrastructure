# IAM role for ECS tasks

#create an IAM role for ECS tasks execution with the necessary permissions to allow the tasks to interact with other AWS services such as CloudWatch Logs for logging and monitoring, and SSM for ECS Exec
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "massar-ecsRole-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "ecsRole-${var.environment}"
    Environment = var.environment
  }
}

# attach the AmazonECSTaskExecutionRolePolicy managed policy to the ECS role
resource "aws_iam_role_policy_attachment" "ecs_role_policy_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# --- Flyway-dedicated execution role -------------------------------------------
# Flyway needs its own execution role because it injects FLYWAY_USER and
# FLYWAY_PASSWORD from Secrets Manager at container start. The app execution
# role must NOT have this permission — the app authenticates via IAM token
# and never touches the master-user secret.

resource "aws_iam_role" "flyway_execution_role" {
  name = "massar-flywayExecutionRole-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "flywayExecutionRole-${var.environment}"
    Environment = var.environment
  }
}


# Allow the Flyway ECS agent to pull the image and send logs (same as the app
# execution role — both need the AWS-managed ECS execution policy).
resource "aws_iam_role_policy_attachment" "flyway_execution_role_policy" {
  role       = aws_iam_role.flyway_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Allow the Flyway ECS agent to resolve FLYWAY_USER and FLYWAY_PASSWORD from
# Secrets Manager. Scoped to the master-user secret only.
resource "aws_iam_role_policy" "flyway_execution_secrets_policy" {
  name = "massar-flyway-execution-secrets-policy-${var.environment}"
  role = aws_iam_role.flyway_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = [var.db_password_secret_arn]
      }
    ]
  })
}












# ceate an IAM role for the ecs tasks 
resource "aws_iam_role" "ecs_task_role" {
  name = "massar-ecsTaskRole-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "massar-ecsTaskRole-${var.environment}"
    Environment = var.environment
  }
}

# Create a custom policy for the ECS task role to allow it to:
# - access S3 for document storage
# - use SSM for ECS Exec
# - send messages to SQS
# - call Cognito admin APIs
# - authenticate to Aurora via IAM token (rds-db:connect as db_iam_user)
resource "aws_iam_role_policy" "ecs_task_policy" {
  # checkov:skip=CKV_AWS_290: ssmmessages actions do not support resource-level restrictions
  # checkov:skip=CKV_AWS_355: ssmmessages actions do not support resource-level restrictions
  name = "massar-ecs-task-policy-${var.environment}"
  role = aws_iam_role.ecs_task_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "allowS3BucketAccess"
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = "arn:aws:s3:::${var.documents_bucket_name}"
      },
      {
        Sid    = "allowS3ObjectAccess"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ]
        Resource = "arn:aws:s3:::${var.documents_bucket_name}/*"
      },

      {
        Sid    = "allowSSMExec"
        Effect = "Allow"
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ]
        Resource = "*"
      },

      {
        Sid    = "allowSQSAccess"
        Effect = "Allow"
        Action = [
          "sqs:SendMessage"
        ]
        Resource = [
          var.sqs_queue_arn,
          var.documents_sqs_queue_arn
        ]
      },
      
      {
        Sid    = "allowCognitoAdminAPIs"
        Effect = "Allow"
        Action = [
          "cognito-idp:AdminCreateUser",
          "cognito-idp:AdminAddUserToGroup",
          "cognito-idp:AdminSetUserPassword",
          "cognito-idp:AdminDeleteUser",
          "cognito-idp:AdminUpdateUserAttributes",
          "cognito-idp:AdminDisableUser",
          "cognito-idp:AdminEnableUser"
        ]
        Resource = "arn:aws:cognito-idp:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:userpool/${var.user_pool_id}"
      },

      {
        Sid    = "allowRDSDBAccess"
        Effect = "Allow"
        Action = ["rds-db:connect"
        ]
        Resource = [
          "arn:aws:rds-db:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:dbuser:${var.rds_proxy_resource_id}/db_iam_user"
        ]
      },
      {
        Sid    = "BedrockInvokeNovaProGuidance"
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream"
        ]
        Resource = [
          # 1. Allow the foundation model in any region to support dynamic Cross-Region Inference routing
          "arn:aws:bedrock:*::foundation-model/amazon.nova-pro-v1:0",

          # 2. Access to the specific regional inference profile initiated from Milan
          "arn:aws:bedrock:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:inference-profile/eu.amazon.nova-pro-v1:0"
        ]
      }
    ]
  })
}
