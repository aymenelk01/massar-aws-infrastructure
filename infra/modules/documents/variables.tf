variable "environment" {
  description = "The environment for which the documents module is being deployed (e.g., dev, staging, prod)."
  type        = string
}

variable "aws_region" {
  description = "The AWS region where the resources will be deployed."
  type        = string
}

variable "lambda_timeout" {
  description = "The timeout for the Lambda function in seconds."
  type        = number
  default     = 90
}

variable "lambda_memory_size" {
  description = "The memory size for the Lambda function in MB."
  type        = number
  default     = 512
}

variable "sqs_message_retention_seconds" {
  description = "The number of seconds SQS should retain a message."
  type        = number
  default     = 86400 //  1 day
}

variable "dlq_message_retention_seconds" {
  description = "The number of seconds the DLQ should retain a message."
  type        = number
  default     = 604800 //  7 day
}

variable "batch_size" {
  description = "The maximum number of records to send to the Lambda function in a single batch."
  type        = number
  default     = 1
}

variable "max_receive_count" {
  description = "The maximum number of times a message can be received before being sent to the DLQ."
  type        = number
  default     = 3
}

variable "documents_bucket_name" {
  description = "The name of the S3 bucket where documents will be stored."
  type        = string
}

variable "documents_bucket_arn" {
  description = "The ARN of the S3 bucket where documents will be stored."
  type        = string
}
