# =============================================================================
# AWS NETWORKING
# =============================================================================

# VPC
resource "aws_vpc" "wordpress_vpc" {
  cidr_block          = "172.16.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "WordPressVPC"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.wordpress_vpc.id

  tags = {
    Name = "IGW-LoadBalancersTeam"
  }
}

# Public Subnets
resource "aws_subnet" "public_2a" {
  vpc_id                  = aws_vpc.wordpress_vpc.id
  cidr_block              = "172.16.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public-subnet-2a"
    Type = "Public"
  }
}

resource "aws_subnet" "public_2b" {
  vpc_id                  = aws_vpc.wordpress_vpc.id
  cidr_block              = "172.16.2.0/24"
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public-subnet-2b"
    Type = "Public"
  }
}

# Private Subnets for RDS
resource "aws_subnet" "private_2a_db" {
  vpc_id            = aws_vpc.wordpress_vpc.id
  cidr_block        = "172.16.20.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "Private-subnet-2a-d"
    Type = "Private-DB"
  }
}

resource "aws_subnet" "private_2b_db" {
  vpc_id            = aws_vpc.wordpress_vpc.id
  cidr_block        = "172.16.21.0/24"
  availability_zone = "${var.aws_region}b"

  tags = {
    Name = "Private-subnet-2b-d"
    Type = "Private-DB"
  }
}

# Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.wordpress_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "PublicRouteTable"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.wordpress_vpc.id

  tags = {
    Name = "PrivateRouteTable"
  }
}

# Route Table Associations
resource "aws_route_table_association" "public_2a" {
  subnet_id      = aws_subnet.public_2a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2b" {
  subnet_id      = aws_subnet.public_2b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_2a_db" {
  subnet_id      = aws_subnet.private_2a_db.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_2b_db" {
  subnet_id      = aws_subnet.private_2b_db.id
  route_table_id = aws_route_table.private.id
}