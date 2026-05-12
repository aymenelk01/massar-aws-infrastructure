# output for the security group ID of the ALB
output "alb_sg_id" {
    description = "The ID of the security group for the ALB"
    value = aws_security_group.alb_sg.id
}

# output for the security group ID of the ECS instances
output "ecs_sg_id" {
    description = "The ID of the security group for the ECS instances"
    value = aws_security_group.ecs_sg.id
}

# output for the security group ID of the VPC endpoints
output "vpc_endpoints_sg_id" {
    description = "The ID of the security group for the VPC endpoints"
    value = aws_security_group.vpc_endpoints_sg.id
}

# output for the security group ID of the elasticache 
output "elasticache_sg_id" {
    description = "The ID of the security group for the ElastiCache instance"
    value = aws_security_group.elasticache_sg.id
}

# output for the security group ID of the RDS Proxy
output "rdsproxy_sg_id" {
    description = "The ID of the security group for the RDS Proxy"
    value = aws_security_group.rdsproxy_sg.id
}

# output for the security group ID of the aurora 
output "aurora_sg_id" {
    description = "The ID of the security group for the aurora "
    value = aws_security_group.aurora_sg.id
}



