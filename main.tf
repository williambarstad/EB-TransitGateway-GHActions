# Terraform Configuration for AWS Infrastructure with VPCs and Transit Gateway

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  description = "The AWS region to deploy resources into"
  type        = string
  default     = "us-west-2"
}

# Create VPC 1
resource "aws_vpc" "vpc1" {
  cidr_block       = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "vpc1"
  }
}

# Create VPC 2
resource "aws_vpc" "vpc2" {
  cidr_block       = "10.1.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "vpc2"
  }
}

# Create Subnets for VPC 1
resource "aws_subnet" "vpc1_subnet" {
  vpc_id     = aws_vpc.vpc1.id
  cidr_block = "10.0.1.0/24"
  tags = {
    Name = "vpc1-subnet"
  }
}

# Create Subnets for VPC 2
resource "aws_subnet" "vpc2_subnet" {
  vpc_id     = aws_vpc.vpc2.id
  cidr_block = "10.1.1.0/24"
  tags = {
    Name = "vpc2-subnet"
  }
}

# Create Transit Gateway
resource "aws_ec2_transit_gateway" "tgw" {
  tags = {
    Name = "my-transit-gateway"
  }
}

# Attach VPC 1 to Transit Gateway
resource "aws_ec2_transit_gateway_vpc_attachment" "vpc1_attachment" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  vpc_id             = aws_vpc.vpc1.id
  subnet_ids         = [aws_subnet.vpc1_subnet.id]

  tags = {
    Name = "vpc1-tgw-attachment"
  }
}

# Attach VPC 2 to Transit Gateway
resource "aws_ec2_transit_gateway_vpc_attachment" "vpc2_attachment" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  vpc_id             = aws_vpc.vpc2.id
  subnet_ids         = [aws_subnet.vpc2_subnet.id]

  tags = {
    Name = "vpc2-tgw-attachment"
  }
}

# Create Route Tables and Add Routes for Transit Gateway
resource "aws_route_table" "vpc1_route_table" {
  vpc_id = aws_vpc.vpc1.id

  route {
    cidr_block              = aws_vpc.vpc2.cidr_block
    transit_gateway_id      = aws_ec2_transit_gateway.tgw.id
  }

  tags = {
    Name = "vpc1-route-table"
  }
}

resource "aws_route_table" "vpc2_route_table" {
  vpc_id = aws_vpc.vpc2.id

  route {
    cidr_block              = aws_vpc.vpc1.cidr_block
    transit_gateway_id      = aws_ec2_transit_gateway.tgw.id
  }

  tags = {
    Name = "vpc2-route-table"
  }
}

# Associate Route Tables with Subnets
resource "aws_route_table_association" "vpc1_subnet_association" {
  subnet_id      = aws_subnet.vpc1_subnet.id
  route_table_id = aws_route_table.vpc1_route_table.id
}

resource "aws_route_table_association" "vpc2_subnet_association" {
  subnet_id      = aws_subnet.vpc2_subnet.id
  route_table_id = aws_route_table.vpc2_route_table.id
} 
