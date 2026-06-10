output "rds_proxy_endpoint" {
  description = "The endpoint of the RDS proxy"
  value       = aws_db_proxy.proxy.endpoint
}

output "aurora_cluster_endpoint" {
  description = "The endpoint of the Aurora cluster"
  value       = aws_rds_cluster.aurora.endpoint
}
  
output "db_secret_arn" {
  description = "The ARN of the database secret"
  value       = aws_secretsmanager_secret.credential_secret.arn
}

output "db_name" {
  description = "the name of the database"
  value       = aws_rds_cluster.aurora.database_name
}

output "secretmanager_arn" {
  description = "the ARN of the secret manager"
  value       = aws_secretsmanager_secret.credential_secret.arn
}