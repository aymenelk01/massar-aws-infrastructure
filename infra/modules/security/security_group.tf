# ==========================================
# APPLICATION LOAD BALANCER (ALB) GROUP
# ==========================================
resource "aws_security_group" "alb_sg" {
  name        = "ALB-SG-${var.environment}"
  description = "Security group for the Application Load Balancer"
  vpc_id      = var.vpc_id
  
  tags = {
    Name = "ALB-SG-${var.environment}"
  }
}

# ==========================================
# ELASTIC CONTAINER SERVICE (ECS) GROUP
# ==========================================
resource "aws_security_group" "ecs_sg" {
  name        = "ECS-SG-${var.environment}"
  description = "Security group for the ECS instances"
  vpc_id      = var.vpc_id

   tags = {
    Name = "ECS-SG-${var.environment}"
  }
}

# ==========================================
# AWS PRIVELINK VPC ENDPOINTS GROUP
# ==========================================
resource "aws_security_group" "vpc_endpoints_sg" {
  name        = "VPCEndpoints-SG-${var.environment}"
  description = "Security group for the VPC endpoints"
  vpc_id      = var.vpc_id

  tags = {
    Name = "VPCEndpoints-SG-${var.environment}"
  }
}

# ==========================================
# ELASTICACHE (REDIS CACHE) GROUP
# ==========================================
resource "aws_security_group" "elasticache_sg" {
  name        = "ElastiCache-SG-${var.environment}"
  description = "Security group for the ElastiCache instance"
  vpc_id      = var.vpc_id

  tags = {
    Name = "ElastiCache-SG-${var.environment}"
  }
}

# ==========================================
# RDS PROXY TRAFFIC MANAGER GROUP
# ==========================================
resource "aws_security_group" "rdsproxy_sg" {
  name        = "RDSProxy-SG-${var.environment}"
  description = "Security group for the RDS Proxy"
  vpc_id      = var.vpc_id

  tags = {
    Name = "RDSProxy-SG-${var.environment}"
  }
}

# ==========================================
# AURORA DATABASE STORAGE CLUSTER GROUP
# ==========================================
resource "aws_security_group" "aurora_sg" {
  name        = "Aurora-SG-${var.environment}"
  description = "Security group for the Aurora instance"
  vpc_id      = var.vpc_id

  tags = {
    Name = "Aurora-SG-${var.environment}"
  }
}
