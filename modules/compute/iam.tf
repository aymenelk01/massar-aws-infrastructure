# IAM role for ECS tasks

#create an IAM role for ECS tasks
resource "aws_iam_role" "ecs_role" {
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
    name = "ecsRole-${var.environment}"
    Environment = var.environment
  }
}

# attach the AmazonECSTaskExecutionRolePolicy managed policy to the ECS role
resource "aws_iam_role_policy_attachment" "ecs_role_policy_attachment" {
  role       = aws_iam_role.ecs_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# create a custom policy for the ECS role to allow it to access the ssm messages for ECS Exec
resource "aws_iam_role_policy" "ecs_exec_policy" {
  name = "ecs-exec-policy-${var.environment}"
  role = aws_iam_role.ecs_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ]
        Resource = "*"
      }
    ]
  })
}