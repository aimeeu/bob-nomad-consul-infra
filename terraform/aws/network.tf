# VPC Configuration
resource "aws_vpc" "nomad_consul_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name  = "${var.project_name}-vpc"
    Owner = var.owner
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.nomad_consul_vpc.id

  tags = {
    Name  = "${var.project_name}-igw"
    Owner = var.owner
  }
}

# Public Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.nomad_consul_vpc.id
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]

  tags = {
    Name  = "${var.project_name}-public-subnet"
    Owner = var.owner
  }
}

# Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.nomad_consul_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name  = "${var.project_name}-public-rt"
    Owner = var.owner
  }
}

# Route Table Association
resource "aws_route_table_association" "public_rta" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# Security Group
resource "aws_security_group" "nomad_consul_sg" {
  name        = "${var.project_name}-sg"
  description = "Security group for Nomad and Consul cluster"
  vpc_id      = aws_vpc.nomad_consul_vpc.id

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
    description = "SSH access"
  }

  # Consul Server RPC
  ingress {
    from_port   = 8300
    to_port     = 8300
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Consul Server RPC"
  }

  # Consul Serf LAN
  ingress {
    from_port   = 8301
    to_port     = 8301
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Consul Serf LAN TCP"
  }

  ingress {
    from_port   = 8301
    to_port     = 8301
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr]
    description = "Consul Serf LAN UDP"
  }

  # Consul HTTP API
  ingress {
    from_port   = 8500
    to_port     = 8500
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
    description = "Consul HTTP API"
  }

  # Consul DNS
  ingress {
    from_port   = 8600
    to_port     = 8600
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Consul DNS TCP"
  }

  ingress {
    from_port   = 8600
    to_port     = 8600
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr]
    description = "Consul DNS UDP"
  }

  # Nomad HTTP API
  ingress {
    from_port   = 4646
    to_port     = 4646
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
    description = "Nomad HTTP API"
  }

  # Nomad RPC
  ingress {
    from_port   = 4647
    to_port     = 4647
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Nomad RPC"
  }

  # Nomad Serf
  ingress {
    from_port   = 4648
    to_port     = 4648
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Nomad Serf TCP"
  }

  ingress {
    from_port   = 4648
    to_port     = 4648
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr]
    description = "Nomad Serf UDP"
  }

  # Allow all internal traffic
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
    description = "Allow all internal traffic"
  }

  # Egress - allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name  = "${var.project_name}-sg"
    Owner = var.owner
  }
}

# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

