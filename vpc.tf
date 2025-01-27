provider "aws" {
  region     = "us-west-2"
  access_key = "my-access-key"
  secret_key = "my-secret-key"
}

resource "aws_vpc" "vpc" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "demo_vpc"
  }
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "192.168.1.0/24"

  tags = {
    Name = "Public"
  }
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "192.168.3.0/24"

  tags = {
    Name = "Private"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "IGW"
  }
}
resource "aws_eip" "ip" {
  vpc = true
}

resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.ip.id
  subnet_id     = aws_subnet.private.id

  tags = {
    Name = "NGW"
  }
}

resource "aws_route_table" "rt1" {
  vpc_id = "${aws_vpc.default.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.igw.id}"
  }
tags = {
    Name = "custom"
  }
}

resource "aws_route_table" "rt2" {
  vpc_id = "${aws_vpc.vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_nat_gateway.ngw.id}"
  }
tags = {
    Name = "main"
  }
}

resource "aws_route_table_association" "as_1" {
  subnet_id      = "${aws_subnet.public.id}"
  route_table_id = "${aws_route_table.rt1.id}"
}

resource "aws_route_table_association" "as_2" {
  subnet_id      = "${aws_subnet.private.id}"
  route_table_id = "${aws_route_table.rt2.id}"
}

resource "aws_security_group" "sg" {
  name        = "SecurityG1"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.main.cidr_block]
    ipv6_cidr_blocks = [aws_vpc.vpc.cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SecurityG1"
  }
}