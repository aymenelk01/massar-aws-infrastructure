# ------------------------------------------
# ALB Rule Definitions
# ------------------------------------------
resource "aws_vpc_security_group_ingress_rule" "alb_from_cloudfront" {
  # checkov:skip=CKV_AWS_260:False Positive. Source traffic is restricted exclusively to CloudFront IPs via prefix lists, not 0.0.0.0/0.

  security_group_id = aws_security_group.alb_sg.id
  description       = "Allow inbound HTTP traffic strictly from CloudFront edge locations"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  prefix_list_id    = data.aws_ec2_managed_prefix_list.cloudfront.id # allow traffic from the AWS-managed prefix list for CloudFront, which allows only CloudFront to access the ALB on port 80, enhancing security by restricting access to the ALB to only CloudFront and preventing direct access from the internet
}

resource "aws_vpc_security_group_egress_rule" "alb_to_ecs" {
  security_group_id            = aws_security_group.alb_sg.id
  description                  = "Allow outbound traffic strictly to backend ECS tasks on container port"
  from_port                    = 3000
  to_port                      = 3000
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.ecs_sg.id
}

# ------------------------------------------
# ECS Rule Definitions
# ------------------------------------------
resource "aws_vpc_security_group_ingress_rule" "ecs_from_alb" {
  security_group_id            = aws_security_group.ecs_sg.id
  description                  = "Allow inbound web traffic exclusively from the ALB on port 3000"
  from_port                    = 3000
  to_port                      = 3000
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.alb_sg.id
}


resource "aws_vpc_security_group_egress_rule" "ecs_to_vpc_dns_udp" {
  security_group_id = aws_security_group.ecs_sg.id
  description       = "Allow outbound UDP DNS queries to the VPC AmazonProvidedDNS because ECS containers cannot resolve the domain names for Aurora Database, ElastiCache cluster, or SQS endpoints without outbound access to port 53"
  from_port         = 53
  to_port           = 53
  ip_protocol       = "udp"
  cidr_ipv4         = var.vpc_cidr_block # allow traffic to the entire VPC CIDR, which includes the AmazonProvidedDNS IP address (the .2 address in the VPC CIDR) and ensures that the ECS tasks can resolve domain names for external communication and service discovery within the VPC
}

resource "aws_vpc_security_group_egress_rule" "ecs_to_vpc_dns_tcp" {
  security_group_id = aws_security_group.ecs_sg.id
  description       = "Allow outbound TCP DNS queries to the VPC AmazonProvidedDNS"
  from_port         = 53
  to_port           = 53
  ip_protocol       = "tcp"
  cidr_ipv4         = var.vpc_cidr_block # allow traffic to the entire VPC CIDR, which includes the AmazonProvidedDNS IP address (the .2 address in the VPC CIDR) and ensures that the ECS tasks can resolve domain names for external communication and service discovery within the VPC
}


resource "aws_vpc_security_group_egress_rule" "ecs_to_vpc_endpoints" {
  security_group_id            = aws_security_group.ecs_sg.id
  description                  = "Allow outbound API traffic to private AWS Interface Endpoints"
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.vpc_endpoints_sg.id
}

resource "aws_vpc_security_group_egress_rule" "ecs_to_elasticache" {
  security_group_id            = aws_security_group.ecs_sg.id
  description                  = "Allow outbound caching commands to the ElastiCache cluster"
  from_port                    = 6379
  to_port                      = 6379
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.elasticache_sg.id
}

resource "aws_vpc_security_group_egress_rule" "ecs_to_rds_proxy" {
  security_group_id            = aws_security_group.ecs_sg.id
  description                  = "Allow outbound database pool queries to the RDS Proxy endpoint"
  from_port                    = 3306
  to_port                      = 3306
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.rdsproxy_sg.id
}

resource "aws_vpc_security_group_egress_rule" "ecs_to_s3" {
  security_group_id = aws_security_group.ecs_sg.id
  description       = "Allow outbound HTTPS traffic to S3 Gateway IP ranges for pulling ECR images"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  prefix_list_id    = data.aws_ec2_managed_prefix_list.s3.id
}

resource "aws_vpc_security_group_egress_rule" "ecs_to_aurora" {
  security_group_id            = aws_security_group.ecs_sg.id
  description                  = "Allow outbound database queries directly to the Aurora cluster (e.g. for Flyway migrations)"
  from_port                    = 3306
  to_port                      = 3306
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.aurora_sg.id
}

# ------------------------------------------
# VPC Endpoints Rule Definitions
# ------------------------------------------
resource "aws_vpc_security_group_ingress_rule" "endpoints_from_ecs" {
  security_group_id            = aws_security_group.vpc_endpoints_sg.id
  description                  = "Allow inbound encrypted traffic from the container application tier"
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.ecs_sg.id
}

# ------------------------------------------
# ElastiCache Rule Definitions
# ------------------------------------------
resource "aws_vpc_security_group_ingress_rule" "redis_from_ecs" {
  security_group_id            = aws_security_group.elasticache_sg.id
  description                  = "Allow inbound microsecond data queries strictly from the app container group"
  from_port                    = 6379
  to_port                      = 6379
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.ecs_sg.id
}

# ------------------------------------------
# RDS Proxy Rule Definitions
# ------------------------------------------
resource "aws_vpc_security_group_ingress_rule" "proxy_from_ecs" {
  security_group_id            = aws_security_group.rdsproxy_sg.id
  description                  = "Allow inbound pooled connections from the application tasks"
  from_port                    = 3306
  to_port                      = 3306
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.ecs_sg.id
}

resource "aws_vpc_security_group_egress_rule" "proxy_to_aurora" {
  security_group_id            = aws_security_group.rdsproxy_sg.id
  description                  = "Allow outbound traffic forwarding from proxy pool straight into database instances"
  from_port                    = 3306
  to_port                      = 3306
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.aurora_sg.id
}

# ------------------------------------------
# Aurora Cluster Rule Definitions
# ------------------------------------------
resource "aws_vpc_security_group_ingress_rule" "aurora_from_proxy" {
  security_group_id            = aws_security_group.aurora_sg.id
  description                  = "Allow inbound database traffic strictly originating from the RDS Proxy pool"
  from_port                    = 3306
  to_port                      = 3306
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.rdsproxy_sg.id
}

resource "aws_vpc_security_group_ingress_rule" "aurora_from_ecs" {
  security_group_id            = aws_security_group.aurora_sg.id
  description                  = "Allow inbound database traffic directly from the ECS tier (e.g. for Flyway migrations)"
  from_port                    = 3306
  to_port                      = 3306
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.ecs_sg.id
}
