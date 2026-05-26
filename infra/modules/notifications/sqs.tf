# Create an SQS queue to be used as a dead-letter queue (DLQ) for the notifications system.
resource "aws_sqs_queue" "dlq" {
  name                      = "${var.environment}-notifications-dlq"
  message_retention_seconds = var.dlq_message_retention_seconds

  tags = {
    Name        = "${var.environment}-notifications-dlq"
    Environment = var.environment
    Module      = "notifications"
  }
}

# Create the main SQS queue for the notifications system, which will use the DLQ for messages that fail processing.
resource "aws_sqs_queue" "main" {
  name                       = "${var.environment}-notifications-queue"
  visibility_timeout_seconds = local.visibility_timeout
  message_retention_seconds  = var.sqs_message_retention_seconds
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = var.max_receive_count
  })

  tags = {
    Name        = "${var.environment}-notifications-queue"
    Environment = var.environment
    Module      = "notifications"
  }
}
