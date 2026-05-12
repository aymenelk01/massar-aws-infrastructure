# create an vpc endpoint for ecr
resource "aws_vpc_endpoint" "ecr_api" {
    vpc_id = var.vpc_id
    service_name = "com.amazonaws.${var.aws_region}.ecr.api"
    vpc_endpoint_type = "Interface"
    private_dns_enabled = true
    
        subnet_ids = var.private_app_subnet_ids
        security_group_ids = [var.vpc_endpoints_sg_id]

    tags = {
        Name = "ECRAPIInterfaceEndpoint-${var.environment}"
        Environment = var.environment
}
}

# create an vpc endpoint for ecr-dkr
resource "aws_vpc_endpoint" "ecr_dkr" {
    vpc_id = var.vpc_id
    service_name = "com.amazonaws.${var.aws_region}.ecr.dkr"
    vpc_endpoint_type = "Interface"
    private_dns_enabled = true  
    
        subnet_ids = var.private_app_subnet_ids
        security_group_ids = [var.vpc_endpoints_sg_id]
        
    tags = {
        Name = "ECRDKRInterfaceEndpoint-${var.environment}"
        Environment = var.environment
}
}

# create an vpc endpoint for logs
resource "aws_vpc_endpoint" "logs" {
    vpc_id = var.vpc_id
    service_name = "com.amazonaws.${var.aws_region}.logs"
    vpc_endpoint_type = "Interface"
    private_dns_enabled = true
    
        subnet_ids = var.private_app_subnet_ids
        security_group_ids = [var.vpc_endpoints_sg_id]
        
    tags = {
        Name = "LogsInterfaceEndpoint-${var.environment}"
        Environment = var.environment
}
}