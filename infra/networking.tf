resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.common_tags, { Name = "${local.name}-vpc" })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
  tags   = merge(local.common_tags, { Name = "${local.name}-igw" })
}

# Public subnets (ALB + NAT)
resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, { Name = "${local.name}-public-${var.azs[count.index]}" })
}

# Private Web subnets
resource "aws_subnet" "web_private" {
  count             = 2
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.web_private_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]

  tags = merge(local.common_tags, { Name = "${local.name}-web-private-${var.azs[count.index]}" })
}

# Private App subnets
resource "aws_subnet" "app_private" {
  count             = 2
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.app_private_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]

  tags = merge(local.common_tags, { Name = "${local.name}-app-private-${var.azs[count.index]}" })
}

# Private DB subnets
resource "aws_subnet" "db_private" {
  count             = 2
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.db_private_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]

  tags = merge(local.common_tags, { Name = "${local.name}-db-private-${var.azs[count.index]}" })
}

# Public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags   = merge(local.common_tags, { Name = "${local.name}-public-rt" })
}

resource "aws_route" "public_default" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_assoc" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# NAT per AZ
resource "aws_eip" "nat" {
  count  = 2
  domain = "vpc"
  tags   = merge(local.common_tags, { Name = "${local.name}-nat-eip-${var.azs[count.index]}" })
}

resource "aws_nat_gateway" "nat" {
  count         = 2
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(local.common_tags, { Name = "${local.name}-nat-${var.azs[count.index]}" })

  depends_on = [aws_internet_gateway.igw]
}

# Private route tables (web + app) each AZ -> its NAT
resource "aws_route_table" "web_private" {
  count  = 2
  vpc_id = aws_vpc.this.id
  tags   = merge(local.common_tags, { Name = "${local.name}-web-rt-${var.azs[count.index]}" })
}

resource "aws_route_table" "app_private" {
  count  = 2
  vpc_id = aws_vpc.this.id
  tags   = merge(local.common_tags, { Name = "${local.name}-app-rt-${var.azs[count.index]}" })
}

resource "aws_route" "web_private_default" {
  count                  = 2
  route_table_id         = aws_route_table.web_private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat[count.index].id
}

resource "aws_route" "app_private_default" {
  count                  = 2
  route_table_id         = aws_route_table.app_private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat[count.index].id
}

resource "aws_route_table_association" "web_private_assoc" {
  count          = 2
  subnet_id      = aws_subnet.web_private[count.index].id
  route_table_id = aws_route_table.web_private[count.index].id
}

resource "aws_route_table_association" "app_private_assoc" {
  count          = 2
  subnet_id      = aws_subnet.app_private[count.index].id
  route_table_id = aws_route_table.app_private[count.index].id
}

# DB route tables: kept isolated (no default route) for best practice
resource "aws_route_table" "db_private" {
  count  = 2
  vpc_id = aws_vpc.this.id
  tags   = merge(local.common_tags, { Name = "${local.name}-db-rt-${var.azs[count.index]}" })
}

resource "aws_route_table_association" "db_private_assoc" {
  count          = 2
  subnet_id      = aws_subnet.db_private[count.index].id
  route_table_id = aws_route_table.db_private[count.index].id
}
