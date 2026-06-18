
# This file defines the AWS Lambda function for the notifications module.

# create a archive file resource to package the lambda function code into a zip file. The source_file points to the lambda_function.py file, and the output_path specifies where the zip file will be created.
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda_function.py"
  output_path = "${path.module}/lambda_function.zip"
}

# create the AWS Lambda function resource. The function_name is set based on the environment variable, and the role is assigned from the IAM role created in the iam.tf file. The handler specifies the entry point for the Lambda function, and the runtime is set to Python 3.12. The timeout and memory_size are configurable through variables. The source_code_hash ensures that the Lambda function is updated whenever the code changes.
resource "aws_lambda_function" "notifications_lambda" {
  # checkov:skip=CKV_AWS_272:AWS Signer overhead is unnecessary for an isolated portfolio pipeline.
  # checkov:skip=CKV_AWS_115:Portfolio project with low traffic; unreserved concurrency is perfectly fine.
  # checkov:skip=CKV_AWS_116:DLQ is handled at the SQS trigger level, not the function level.
  # checkov:skip=CKV_AWS_117:Lambda does not access VPC resources — placing it inside VPC adds cold start latency with no security benefit
  # checkov:skip=CKV_AWS_173:Default AWS KMS encryption is sufficient for this portfolio project.
  function_name    = "${var.environment}-notifications-lambda"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_size
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  depends_on       = [aws_cloudwatch_log_group.lambda_log_group]

  filename = data.archive_file.lambda_zip.output_path

  tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.notifications_topic.arn
      SES_SENDER_EMAIL = "aymenelkharchi15@gmail.com"
    }
  }

  tags = {
    Name        = "${var.environment}-notifications-lambda"
    Environment = var.environment
    Module      = "notifications"
  }

}

# create an event source mapping to connect the Lambda function to the SQS queue. This allows the Lambda function to be triggered whenever a new message is added to the SQS queue. The batch_size variable determines how many messages are sent to the Lambda function in a single batch.
resource "aws_lambda_event_source_mapping" "sqs_event_source" {
  event_source_arn = aws_sqs_queue.main.arn
  function_name    = aws_lambda_function.notifications_lambda.arn
  batch_size       = var.batch_size
  enabled          = true
}
