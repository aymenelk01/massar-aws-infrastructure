output "rds_proxy_endpoint" {
  description = "The endpoint of the RDS proxy"
  value       = aws_db_proxy.proxy.endpoint
}

output "rds_proxy_resource_id" {
  value       = aws_db_proxy.proxy.id
  description = "The resource ID of the RDS Proxy"
  }

output "aurora_cluster_endpoint" {
  description = "The endpoint of the Aurora cluster"
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