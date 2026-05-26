

output "ecr_api_endpoint_id" {
    description = "The ID of the VPC endpoint for ECR API"
    value = aws_vpc_endpoint.ecr_api.id
  
}

output "ecr_dkr_endpoint_id" {
    description = "The ID of the VPC endpoint for ECR DKR"
    value = aws_vpc_endpoint.ecr_dkr.id
  
}

output "logs_endpoint_id" {
    description = "The ID of the VPC endpoint for Logs"
    value = aws_vpc_endpoint.logs.id
  
}