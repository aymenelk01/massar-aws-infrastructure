## Create security group for the application load balancer and allow inbound traffic on ports 80 and 443, and allow all outbound traffic
resource "aws_security_group" "alb_sg" {
  name        = "ALB-SG-${var.environment}"
  description = "Security group for the Application Load Balancer"
  vpc_id      = var.vpc_id

  # allow inbound traffic on port 443
  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    prefix_list_ids = [var.cloudfront_prefix_list_id] # AWS-managed prefix list for CloudFront
  }
  # allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ALB-SG-${var.environment}"
  }
}

## Create security group for the ECS instances and allow inbound traffic on ports 80 and 443 from the ALB security group, and allow all outbound traffic
resource "aws_security_group" "ecs_sg" {
  name        = "ECS-SG-${var.environment}"
  description = "Security group for the ECS instances"
  vpc_id      = var.vpc_id

  # allow traffic from the ALB security group on port 80
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id] # allow traffic from the ALB security group
  }

  # allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ECS-SG-${var.environment}"
  }
}

# Create security group for the VPC endpoints and allow inbound traffic on port 443 from the ECS security group, and allow all outbound traffic
resource "aws_security_group" "vpc_endpoints_sg" {
  name        = "VPCEndpoints-SG-${var.environment}"
  description = "Security group for the VPC endpoints"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_sg.id] # allow traffic from the ECS security group    
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "VPCEndpoints-SG-${var.environment}"
  }

}

# Create security group for the ElastiCache instance and allow inbound traffic on port 6379 from the ECS security group, and allow all outbound traffic
resource "aws_security_group" "elasticache_sg" {
  name        = "ElastiCache-SG-${var.environment}"
  description = "Security group for the ElastiCache instance"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 6379 # allow traffic on port 6379 for Redis
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_sg.id] # allow traffic from the ECS security group    
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ElastiCache-SG-${var.environment}"
  }
}

# Create security group for the RDS Proxy and allow inbound traffic on port 3306 from the ECS security group, and allow all outbound traffic
resource "aws_security_group" "rdsproxy_sg" {
  name        = "RDSProxy-SG-${var.environment}"
  description = "Security group for the RDS Proxy"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_sg.id] # allow traffic from the ECS security group    
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "RDSProxy-SG-${var.environment}"
  }
}


## create security group for the Aurora instance and allow inbound traffic on port 3306 from RDS Proxy security group
resource "aws_security_group" "aurora_sg" {
  name        = "Aurora-SG-${var.environment}"
  description = "Security group for the Aurora instance"
  vpc_id      = var.vpc_id

  # allow traffic from RDS Proxy security group group on port 3306
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.rdsproxy_sg.id] # allow traffic from the RDS Proxy security group
  }
  # allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Aurora-SG-${var.environment}"
  }
}   
