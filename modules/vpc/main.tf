# main.tf — VPC, subnets, IGW, optional NAT, and route tables

# -----------------------------------------------------------------------------
# Availability Zones — pick the first N available AZs in the region dynamically
# -----------------------------------------------------------------------------

data "aws_availability_zones" "available" { # Data source: query AWS for AZ names
  state = "available"                       # Only include AZs that are currently usable
}                                           # End AZ data source

locals {                                         # Locals hold computed values reused below
  azs = slice(                                   # Take a slice of the AZ name list
    data.aws_availability_zones.available.names, # Full list of available AZ names
    0,                                           # Start index (first AZ)
    var.az_count                                 # End index exclusive → first az_count AZs
  )                                              # End slice()

  common_tags = merge( # Merge caller tags with module defaults
    var.tags,          # Tags passed in by the app
    {                  # Inline map of module-owned tags
      Module = "vpc"   # Mark resources as coming from this module
    }                  # End inline map
  )                    # End merge()
}                      # End locals

# -----------------------------------------------------------------------------
# VPC — isolated network boundary for the app
# -----------------------------------------------------------------------------

resource "aws_vpc" "main" {             # Create the VPC resource
  cidr_block           = var.cidr_block # Assign the primary IPv4 CIDR from input
  enable_dns_support   = true           # Allow DNS resolution inside the VPC
  enable_dns_hostnames = true           # Give instances DNS hostnames when they have public IPs

  tags = merge(                       # Build the tag map for this VPC
    local.common_tags,                # Start from shared tags
    {                                 # Add Name tag specific to this resource
      Name = "${var.name_prefix}-vpc" # e.g. web-api-dev-vpc
    }                                 # End Name map
  )                                   # End merge()
}                                     # End aws_vpc.main

# -----------------------------------------------------------------------------
# Public subnets — ALB, NAT, bastion (map public IP on launch)
# -----------------------------------------------------------------------------

resource "aws_subnet" "public" { # Create public subnets
  count = var.az_count           # One subnet per AZ

  vpc_id                  = aws_vpc.main.id # Place subnet inside this VPC
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name_prefix}-public-${local.azs[count.index]}"
      Tier = "public"
    }
  )
}

# -----------------------------------------------------------------------------
# Private subnets — app tasks/instances (no public IP)
# -----------------------------------------------------------------------------

resource "aws_subnet" "private" {
  count = var.az_count

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet_cidrs[count.index]
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = false

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name_prefix}-private-${local.azs[count.index]}"
      Tier = "private"
    }
  )
}

# -----------------------------------------------------------------------------
# Internet Gateway — inbound/outbound path for public subnets
# -----------------------------------------------------------------------------

resource "aws_internet_gateway" "main" { # Create an Internet Gateway
  vpc_id = aws_vpc.main.id               # Attach IGW to this VPC

  tags = merge(                       # Tag the IGW
    local.common_tags,                # Shared tags
    {                                 # Resource-specific tags
      Name = "${var.name_prefix}-igw" # Stable Name tag
    }                                 # End specific tags
  )                                   # End merge()
}                                     # End aws_internet_gateway.main

# -----------------------------------------------------------------------------
# NAT Gateway — optional outbound internet for private subnets (costs money)
# -----------------------------------------------------------------------------

resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway ? 1 : 0
  domain = "vpc"

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name_prefix}-nat-eip"
    }
  )

  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "main" {
  count = var.enable_nat_gateway ? 1 : 0

  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name_prefix}-nat-gw"
    }
  )

  depends_on = [aws_internet_gateway.main]
}

# -----------------------------------------------------------------------------
# Public route table — default route to the Internet Gateway
# -----------------------------------------------------------------------------

resource "aws_route_table" "public" { # Route table for public subnets
  vpc_id = aws_vpc.main.id            # Belong to this VPC

  route {                                     # Default route for all non-local traffic
    cidr_block = "0.0.0.0/0"                  # Match any IPv4 destination
    gateway_id = aws_internet_gateway.main.id # Send that traffic to the IGW
  }                                           # End route block

  tags = merge(                             # Tag the public route table
    local.common_tags,                      # Shared tags
    {                                       # Resource-specific tags
      Name = "${var.name_prefix}-public-rt" # Stable Name tag
    }                                       # End specific tags
  )                                         # End merge()
}                                           # End aws_route_table.public

resource "aws_route_table_association" "public" {
  count = var.az_count

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# -----------------------------------------------------------------------------
# Private route table — default route to NAT (when enabled)
# -----------------------------------------------------------------------------

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.main[0].id
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name_prefix}-private-rt"
    }
  )
}

resource "aws_route_table_association" "private" {
  count = var.az_count

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

