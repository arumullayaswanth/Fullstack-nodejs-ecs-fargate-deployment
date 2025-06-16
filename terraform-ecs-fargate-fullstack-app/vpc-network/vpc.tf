provider "aws" {
  region = "us-east-1"
  
}

# Create VPC
resource "aws_vpc" "ecs_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support   = true   # Enables DNS resolution
  enable_dns_hostnames = true   # Enables DNS hostnames
    tags = {
    Name = "ecs-vpc"
  }
}

# Create Public Subnets in Two AZs
resource "aws_subnet" "public_subnet1" {
  vpc_id                  = aws_vpc.ecs_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
   tags = {
    Name = "ecs-public1"
  }
}

resource "aws_subnet" "public_subnet2" {
  vpc_id                  = aws_vpc.ecs_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
   tags = {
    Name = "ecs-public2"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "ecs_gw" {
  vpc_id = aws_vpc.ecs_vpc.id
   tags = {
    Name = "ecs-ig"
  }
}

# Route Table
resource "aws_route_table" "ecs_rt" {
  vpc_id = aws_vpc.ecs_vpc.id
   tags = {
    Name = "ecs-rt-public"
  }
}

resource "aws_route" "ecs_route" {
  route_table_id         = aws_route_table.ecs_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.ecs_gw.id
}

# Associate Route Table with Subnets
resource "aws_route_table_association" "ecs_rta1" {
  subnet_id      = aws_subnet.public_subnet1.id
  route_table_id = aws_route_table.ecs_rt.id
}

resource "aws_route_table_association" "ecs_rta2" {
  subnet_id      = aws_subnet.public_subnet2.id
  route_table_id = aws_route_table.ecs_rt.id
}


resource "aws_subnet" "private_subnet1" {
  vpc_id                  = aws_vpc.ecs_vpc.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "us-east-1a"
  tags = {
    Name = "ecs-private1"
  } 
}

resource "aws_subnet" "private_subnet2" {
  vpc_id                  = aws_vpc.ecs_vpc.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = "us-east-1b"
 tags = {
    Name = "ecs-private2"
  }
}

resource "aws_eip" "elasticip" {
  
}
resource "aws_nat_gateway" "natgateway" {
  subnet_id = aws_subnet.public_subnet1.id
  connectivity_type = "public"
  allocation_id = aws_eip.elasticip.id
   tags = {
    Name = "ecs-nat"
  }
}

resource "aws_route_table" "ecs_rt_private" {
  vpc_id = aws_vpc.ecs_vpc.id
   tags = {
    Name = "ecs-rt-private"
  }
}

resource "aws_route" "ecs_route_private" {
  route_table_id         = aws_route_table.ecs_rt_private.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.natgateway.id
}

# Associate Route Table with Subnets
resource "aws_route_table_association" "ecs_rta1_private" {
  subnet_id      = aws_subnet.private_subnet1.id
  route_table_id = aws_route_table.ecs_rt_private.id
}

resource "aws_route_table_association" "ecs_rta2_private" {
  subnet_id      = aws_subnet.private_subnet2.id
  route_table_id = aws_route_table.ecs_rt_private.id
}


# Security Group for ALB
resource "aws_security_group" "lb_sg" {
  vpc_id = aws_vpc.ecs_vpc.id
  tags = {
    Name = "lb-sg"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
