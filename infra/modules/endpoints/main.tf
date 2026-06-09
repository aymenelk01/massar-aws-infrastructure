# ------------------------------------------
# Dynamic VPC Interface Endpoints Setup
# ------------------------------------------
resource "aws_vpc_endpoint" "interfaces" {
  for_each            = var.vpc_endpoint_services
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.region}.${each.value}"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = var.private_app_subnet_ids
  security_group_ids  = [var.vpc_endpoints_sg_id]

  tags = {
    Name        = "${each.value}-endpoint-${var.environment}"
    Environment = var.environment
  }
}