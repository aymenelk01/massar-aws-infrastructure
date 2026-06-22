#1. create a route table for public subnets
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

# 2. associate the public subnets with the route table
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public_RT.id
}

# 3. create a route table for app subnets
resource "aws_route_table" "app_RT" {
  count  = length(var.private_app_subnet_cidrs)
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "PrivateAppRouteTable-${var.environment}-${count.index + 1}"
  }
}

# 4. create a route table for db subnets
resource "aws_route_table" "db_RT" {
  count  = length(var.private_db_subnet_cidrs)
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "PrivateDbRouteTable-${var.environment}-${count.index + 1}"
  }
}

# 5. associate the app subnets with his route table
resource "aws_route_table_association" "private_app" {
  count          = length(var.private_app_subnet_cidrs)
  subnet_id      = aws_subnet.private_app[count.index].id
  route_table_id = aws_route_table.app_RT[count.index].id
}
# 6. associate the db subnets with his route table
resource "aws_route_table_association" "private_db" {
  count          = length(var.private_db_subnet_cidrs)
  subnet_id      = aws_subnet.private_db[count.index].id
  route_table_id = aws_route_table.db_RT[count.index].id
}
