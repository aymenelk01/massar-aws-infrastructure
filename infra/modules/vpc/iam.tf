resource "aws_iam_role" "vpcflow_role" {
  name = "${var.environment}-vpc-flow-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "${var.environment}-vpc-flow-role"
    Environment = var.environment
    Module      = "vpc"
  }
}


resource "aws_iam_role_policy" "vpcflow_policy" {
  name = "${var.environment}-vpc-flow-policy"
  role = aws_iam_role.vpcflow_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # This statement handles actions that DO NOT support resource-level permissions
        Sid    = "CloudWatchLogsReadOnlyDescribe"
        Effect = "Allow"
        Action = [
          "logs:DescribeLogGroups"

        ]
        Resource = "*"
      },

      {
        Sid    = "CloudWatchLogsStreamsReadOnlyDescribe"
        Effect = "Allow"
        Action = [
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:*:*"
      },

      {
        # This statement restricts write and creation actions to the specific log group path
        Sid    = "CloudWatchLogsWriteRestricted"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          # Target for CreateLogGroup (the log group resource itself)
          "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/vpc/flow-logs/*",
          # Target for CreateLogStream and PutLogEvents (the log streams inside the group)
          "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/vpc/flow-logs/*:*"
        ]
      }
    ]
  })
}
