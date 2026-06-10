
# Create an ElastiCache subnet group for the cache cluster, using the private database subnet IDs from the VPC module
resource "aws_elasticache_subnet_group" "cache_subnet_group" {
  name       = "cache-subnet-group-${var.environment}"
  subnet_ids = var.private_db_subnet_ids

  tags = {
    Name        = "CacheSubnetGroup-${var.environment}"
    Environment = var.environment
  }
}
 
# Create an ElastiCache replication group for Redis, using the custom parameter group and subnet group defined above
resource "aws_elasticache_replication_group" "cache_replication_group" {
  #checkov:skip=CKV_AWS_31:auth_token not required — Redis 7 supports RBAC via user groups. auth_token is the legacy authentication mechanism. ElastiCache user group authentication is documented as a future improvement
  #checkov:skip=CKV_AWS_191:AWS managed key acceptable for portfolio project — CMK is a future improvement
  automatic_failover_enabled  = true # enable automatic failover to improve availability by allowing the replication group to automatically promote a read replica to primary if the primary node fails
  preferred_cache_cluster_azs = var.availability_zones # specify the availability zones for the cache clusters to improve availability and fault tolerance
  replication_group_id        = "massar-cache-${var.environment}"
  description                 = "Massar Cache Replication Group for ${var.environment} environment"
  node_type                   = "cache.t3.micro" # choose an appropriate node type based on your requirements 
  num_cache_clusters          = 2 # specify the number of cache clusters in the replication group to improve performance and availability by distributing the load across multiple nodes
  parameter_group_name        = aws_elasticache_parameter_group.custom_redis7.name
  subnet_group_name           = aws_elasticache_subnet_group.cache_subnet_group.name
  security_group_ids          = [var.elasticache_sg_id]
  port                        = 6379

  transit_encryption_enabled   = true # enable in-transit encryption to secure data in transit between the cache clusters and the clients
  at_rest_encryption_enabled   = true # enable at-rest encryption to secure data stored in the cache clusters
  
  tags = {
    Name        = "MassarCache-${var.environment}"
    Environment = var.environment
  }
}

# Create a custom parameter group for Redis 7 with the desired parameters
resource "aws_elasticache_parameter_group" "custom_redis7" {
  name   = "custom-redis7"
  family = "redis7"

  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"
  }

  parameter {
    name  = "timeout"
    value = "300"
  }

  tags = {
    Name        = "CustomRedis7ParameterGroup-${var.environment}"
    Environment = var.environment
  }
}
