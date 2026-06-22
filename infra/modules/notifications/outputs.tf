output "sqs_queue_url" {
  value       = aws_sqs_queue.main.url
  description = "URL of the SQS queue for notifications"
}

output "sqs_queue_arn" {
  value       = aws_sqs_queue.main.arn
  description = "ARN of the SQS queue for notifications"
}

output "sns_topic_arn" {
  value       = aws_sns_topic.notifications_topic.arn
  description = "ARN of the SNS topic for notifications"
}