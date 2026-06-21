output "documents_sqs_queue_url" {
  value       = aws_sqs_queue.main.url
  description = "URL of the SQS queue for documents"
}

output "documents_sqs_queue_arn" {
  value       = aws_sqs_queue.main.arn
  description = "ARN of the SQS queue for documents"
}

