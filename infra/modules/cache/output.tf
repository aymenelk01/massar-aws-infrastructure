output "elasticache_replication_group_endpoint" {
    description = "The endpoint of the ElastiCache replication group"
    value       = aws_elasticache_replication_group.cache_replication_group.primary_endpoint_address
  
}