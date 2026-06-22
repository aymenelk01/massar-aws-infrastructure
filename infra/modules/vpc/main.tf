# 1. Create a vpc
resource "aws_vpc" "main" {
  # checkov:skip=CKV2_AWS_11: vpc logging is enabled in the vpcflowlogs module, so this is a false positive.
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "Vpc-${var.environment}"
  }

}

#2. create a internet gateway
resource "aws_internet_gateway" "IGW" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "IGW-${var.environment}"
  }

}

# Explicitly restrict the default security group to deny all traffic.
# This prevents any resource from accidentally inheriting permissive default rules.
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id

  # No ingress or egress rules — all traffic denied by default
}