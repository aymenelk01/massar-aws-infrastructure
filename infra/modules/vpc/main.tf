# 1. Create a vpc
resource "aws_vpc" "main" {
    cidr_block = var.vpc_cidr
    enable_dns_hostnames = true
    enable_dns_support = true

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

#4. create a public subnet (tier 1)
resource "aws_subnet" "public" {
    count = length(var.public_subnet_cidrs)
    vpc_id = aws_vpc.main.id
    cidr_block = var.public_subnet_cidrs[count.index]
    availability_zone = var.availability_zones[count.index]
    map_public_ip_on_launch = true

    tags = {
        Name = "PublicSubnet-${var.environment}-${count.index + 1}"
    }   
}

#5. create a private subnet (tier 2)
resource "aws_subnet" "private_app" {
    count = length(var.private_app_subnet_cidrs)
    vpc_id = aws_vpc.main.id
    cidr_block = var.private_app_subnet_cidrs[count.index]
    availability_zone = var.availability_zones[count.index]
    map_public_ip_on_launch = false

    tags = {
        Name = "PrivateAppSubnet-${var.environment}-${count.index + 1}"
    }
  
}

#6. create a private subnet (tier 3)
resource "aws_subnet" "private_db" {
    count = length(var.private_db_subnet_cidrs)
    vpc_id = aws_vpc.main.id
    cidr_block = var.private_db_subnet_cidrs[count.index]
    availability_zone = var.availability_zones[count.index]
    map_public_ip_on_launch = false

    tags = {
        Name = "PrivateDbSubnet-${var.environment}-${count.index + 1}"
    }
  
}

#7. create a route table for public subnets
resource "aws_route_table" "public_RT" {
    vpc_id = aws_vpc.main.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.IGW.id
    }

    tags = {
        Name = "PublicRouteTable-${var.environment}-1"
    }
}

# 8. associate the public subnets with the route table
resource "aws_route_table_association" "public" {
    count = length(var.public_subnet_cidrs)
    subnet_id = aws_subnet.public[count.index].id
    route_table_id = aws_route_table.public_RT.id
}

# 9. create a route table for app subnets
resource "aws_route_table" "app_RT" {
    count = length(var.private_app_subnet_cidrs)
    vpc_id = aws_vpc.main.id

    tags = {
        Name = "PrivateAppRouteTable-${var.environment}-${count.index + 1}"
    }
}

# 10. create a route table for db subnets
resource "aws_route_table" "db_RT" {
    count = length(var.private_db_subnet_cidrs)
    vpc_id = aws_vpc.main.id

    tags = {
        Name = "PrivateDbRouteTable-${var.environment}-${count.index + 1}"
    }
}

# 11. associate the app subnets with his route table
resource "aws_route_table_association" "private_app" {
    count = length(var.private_app_subnet_cidrs)
    subnet_id = aws_subnet.private_app[count.index].id
    route_table_id = aws_route_table.app_RT[count.index].id
}
# 12. associate the db subnets with his route table
resource "aws_route_table_association" "private_db" {
    count = length(var.private_db_subnet_cidrs)
    subnet_id = aws_subnet.private_db[count.index].id
    route_table_id = aws_route_table.db_RT[count.index].id
}