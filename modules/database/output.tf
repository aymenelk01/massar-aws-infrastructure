output "rds_proxy_endpoint" {
  description = "The endpoint of the RDS proxy"
  value       = aws_db_proxy.proxy.endpoint
}

output "aurora_cluster_endpoint" {
  description = "The endpoint of the Aurora cluster"
  value       = aws_rds_cluster.aurora.endpoint
}