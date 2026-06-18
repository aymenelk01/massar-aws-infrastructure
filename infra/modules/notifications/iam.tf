resource "aws_iam_role" "lambda_role" {
  name = "${var.environment}-notifications-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "${var.environment}-notifications-lambda-role"
    Environment = var.environment
    Module      = "notifications"
  }
}

resource "aws_iam_role_policy" "lambda_policy" {
  #checkov:skip=CKV_AWS_355:sns:Publish requires Resource = "*" for direct SMS publishing to phone numbers — AWS does not support resource-level restrictions for this operation
  #checkov:skip=CKV_AWS_290:sns:Publish requires Resource = "*" for direct SMS publishing to phone numbers — AWS does not support resource-level restrictions for this operation
  name = "${var.environment}-notifications-lambda-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.environment}-notifications-lambda",
          "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.environment}-notifications-lambda:*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = aws_sqs_queue.main.arn
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = ["*"]
      },
      {
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail",
        ]
        Resource = "arn:aws:ses:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:identity/aymenelkharchi15@gmail.com"
      }
    ]
  })
}
