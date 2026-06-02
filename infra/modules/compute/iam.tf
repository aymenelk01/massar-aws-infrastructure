# IAM role for ECS tasks

#create an IAM role for ECS tasks execution with the necessary permissions to allow the tasks to interact with other AWS services such as CloudWatch Logs for logging and monitoring, and SSM for ECS Exec
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsRole-${var.environment}"

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


# ceate an IAM role for the ecs tasks 
resource "aws_iam_role" "ecs_task_role" {
  name = "ecsTaskRole-${var.environment}"

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
    Name        = "ecsTaskRole-${var.environment}"
    Environment = var.environment
  }
}

# create a custom policy for the ECS role to allow it to access the S3 bucket for the documents files
resource "aws_iam_role_policy" "ecs_task_policy" {
  # checkov:skip=CKV_AWS_290: ssmmessages actions do not support resource-level restrictions
  # checkov:skip=CKV_AWS_355: ssmmessages actions do not support resource-level restrictions
  name = "ecs-task-policy-${var.environment}"
  role = aws_iam_role.ecs_task_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
        ]
        Resource = "arn:aws:s3:::${var.documents_bucket_name}/*"
      },

      {
        Effect = "Allow"
        Action = [
          "logs:DescribeLogGroups",
          "logs:CreateLogStream",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },

      {
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
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
        ]
        Resource = var.sqs_queue_arn
      },

      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
        ]
        Resource = var.db_secret_arn
      }
    ]
  })
}
