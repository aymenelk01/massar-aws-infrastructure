# create an vpc endpoint for s3
resource "aws_vpc_endpoint" "s3_gateway" {
    vpc_id = aws_vpc.main.id
    service_name = "com.amazonaws.${var.aws_region}.s3"
    vpc_endpoint_type = "Gateway"
    
    # associate the endpoint with all route tables in the VPC
    route_table_ids = concat(
        [aws_route_table.public_RT.id],
        aws_route_table.app_RT[*].id,
    )

    tags = {
        Name = "S3GatewayEndpoint-${var.environment}"
        Environment = var.environment
}
}

# create an vpc endpoint for dynamodb
resource "aws_vpc_endpoint" "dynamodb_gateway" {
    vpc_id = aws_vpc.main.id
    service_name = "com.amazonaws.${var.aws_region}.dynamodb"
    vpc_endpoint_type = "Gateway"
    
    # associate the endpoint with all route tables in the VPC
    route_table_ids = concat(
        [aws_route_table.public_RT.id],
        aws_route_table.app_RT[*].id
    )

    tags = {
        Name = "DynamoDBGatewayEndpoint-${var.environment}"
        Environment = var.environment
}
}

