
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
  automatic_failover_enabled  = true
  preferred_cache_cluster_azs = ["eu-south-1a", "eu-south-1b"] # specify the availability zones for the cache clusters to improve availability and fault tolerance
  replication_group_id        = "massar-cache-${var.environment}"
  description                 = "Massar Cache Replication Group for ${var.environment} environment"
  node_type                   = "cache.t3.micro" # choose an appropriate node type based on your requirements 
  num_cache_clusters          = 2 # specify the number of cache clusters in the replication group to improve performance and availability by distributing the load across multiple nodes
  parameter_group_name        = aws_elasticache_parameter_group.custom_redis7.name
  subnet_group_name           = aws_elasticache_subnet_group.cache_subnet_group.name
  security_group_ids          = [var.elasticache_sg_id]
  port                        = 6379

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
