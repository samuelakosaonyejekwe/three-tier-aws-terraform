# Public ALB
resource "aws_lb" "public" {
  name               = "${local.name}-public-alb"
  load_balancer_type = "application"
  internal           = false
  subnets            = [aws_subnet.public[0].id, aws_subnet.public[1].id]
  security_groups    = [aws_security_group.alb_public_sg.id]

  tags = merge(local.common_tags, { Name = "${local.name}-public-alb" })
}

resource "aws_lb_target_group" "web_tg" {
  name     = "${local.name}-web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.this.id

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = merge(local.common_tags, { Name = "${local.name}-web-tg" })
}

# HTTP -> HTTPS redirect
resource "aws_lb_listener" "public_http" {
  load_balancer_arn = aws_lb.public.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# HTTPS listener (443)
resource "aws_lb_listener" "public_https" {
  load_balancer_arn = aws_lb.public.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate_validation.app_cert_validation.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

# Internal ALB (App tier)
resource "aws_lb" "internal" {
  name               = "${local.name}-internal-alb"
  load_balancer_type = "application"
  internal           = true
  subnets            = [aws_subnet.app_private[0].id, aws_subnet.app_private[1].id]
  security_groups    = [aws_security_group.alb_internal_sg.id]

  tags = merge(local.common_tags, { Name = "${local.name}-internal-alb" })
}

resource "aws_lb_target_group" "app_tg" {
  name     = "${local.name}-app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.this.id

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = merge(local.common_tags, { Name = "${local.name}-app-tg" })
}

resource "aws_lb_listener" "internal_http" {
  load_balancer_arn = aws_lb.internal.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}
