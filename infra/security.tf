# Public ALB SG: allow 80/443 from internet
resource "aws_security_group" "alb_public_sg" {
  name        = "${local.name}-alb-public-sg"
  description = "Public ALB SG"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${local.name}-alb-public-sg" })
}

# Web instances SG: allow 80 only from public ALB
resource "aws_security_group" "web_sg" {
  name        = "${local.name}-web-sg"
  description = "Web tier instances"
  vpc_id      = aws_vpc.this.id

  ingress {
    description     = "HTTP from public ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_public_sg.id]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${local.name}-web-sg" })
}

# Internal ALB SG: allow 80 only from web tier
resource "aws_security_group" "alb_internal_sg" {
  name        = "${local.name}-alb-internal-sg"
  description = "Internal ALB SG"
  vpc_id      = aws_vpc.this.id

  ingress {
    description     = "HTTP from web tier"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${local.name}-alb-internal-sg" })
}

# App instances SG: allow 80 only from internal ALB
resource "aws_security_group" "app_sg" {
  name        = "${local.name}-app-sg"
  description = "App tier instances"
  vpc_id      = aws_vpc.this.id

  ingress {
    description     = "HTTP from internal ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_internal_sg.id]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${local.name}-app-sg" })
}

# DB SG: allow 3306 only from app tier
resource "aws_security_group" "db_sg" {
  name        = "${local.name}-db-sg"
  description = "DB tier"
  vpc_id      = aws_vpc.this.id

  ingress {
    description     = "MySQL from app tier"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }

  egress {
    description = "Outbound (as needed)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${local.name}-db-sg" })
}
