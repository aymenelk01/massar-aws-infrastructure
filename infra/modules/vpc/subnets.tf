# 1. create a public subnet (tier 1)
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false # disable auto-assign public IPs to enhance security because there is just alb who lives in the public subnet and he manages its own IP addresses 


  tags = {
    Name = "PublicSubnet-${var.environment}-${count.index + 1}"
  }
}

# 2. create a private subnet (tier 2)
resource "aws_subnet" "private_app" {
  count                   = length(var.private_app_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_app_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "PrivateAppSubnet-${var.environment}-${count.index + 1}"
  }

}

# 3. create a private subnet (tier 3)
resource "aws_subnet" "private_db" {
  count                   = length(var.private_db_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_db_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "PrivateDbSubnet-${var.environment}-${count.index + 1}"
  }

}