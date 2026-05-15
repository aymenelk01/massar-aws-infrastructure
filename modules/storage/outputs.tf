# outputs for the storage module
output "documents_bucket_name" {
  description = "The name of the S3 bucket for documents"
  value       = aws_s3_bucket.documents_files.bucket
}


output "documents_bucket_id" {
  description = "The ID of the S3 bucket for documents"
  value       = aws_s3_bucket.documents_files.id
}

output "documents_bucket_arn" {
  description = "The ARN of the S3 bucket for documents"
  value       = aws_s3_bucket.documents_files.arn
}

output "documents_bucket_regional_domain_name" {
  description = "The regional domain name of the S3 bucket for documents"
  value       = aws_s3_bucket.documents_files.bucket_regional_domain_name
  
}

output "state_bucket_name" {
  description = "The name of the S3 bucket for state files"
  value       = aws_s3_bucket.state_files.bucket
}

output "state_bucket_arn" {
  description = "The ARN of the S3 bucket for state files"
  value       = aws_s3_bucket.state_files.arn
}

output "logs_bucket_regional_domain_name" {
  description = "The regional domain name of the S3 bucket for log files"
  value       = aws_s3_bucket.logs.bucket_regional_domain_name
}

output "logs_bucket_name" {
  description = "The name of the S3 bucket for log files"
  value       = aws_s3_bucket.logs.bucket
}

output "logs_bucket_arn" {
  description = "The ARN of the S3 bucket for log files"
  value       = aws_s3_bucket.logs.arn
}

output "logs_bucket_id" {
  description = "The ID of the S3 bucket for log files"
  value       = aws_s3_bucket.logs.id
}
