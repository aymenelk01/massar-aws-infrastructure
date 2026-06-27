output "rds_proxy_writer_endpoint" {
  description = "The endpoint of the RDS proxy"
  value       = aws_db_proxy.writer.endpoint
}

output "rds_proxy_reader_endpoint" {
  description = "RDS Proxy read-only endpoint — routes to Aurora reader instances"
  value       = aws_db_proxy_endpoint.reader.endpoint
}

output "rds_proxy_resource_id" {
  value       = element(split(":", aws_db_proxy.writer.arn), 6)
  description = "The resource ID of the RDS Proxy (prx-XXXX format, used in rds-db:connect IAM ARNs)"
}

output "aurora_writer_endpoint" {
  description = "The endpoint of the Aurora writer instance"
  value       = aws_rds_cluster.aurora.endpoint
}

output "db_name" {
  description = "the name of the database"
  value       = aws_rds_cluster.aurora.database_name
}

output "db_password_secret_arn" {
  value       = aws_rds_cluster.aurora.master_user_secret[0].secret_arn
  description = "The ARN of the AWS-managed master password secret"
}