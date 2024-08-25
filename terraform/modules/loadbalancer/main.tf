
locals {
  commmon_tags = merge(var.additional_tags,
    {
      module_version = 1.0
  })
}

data "aws_route53_zone" "hzone" {
  name = var.zone_name
}

# Create ALB Target Group
resource "aws_lb_target_group" "alb_target" {
  name        = "${var.name}-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"
  health_check {
    path = "/"
    port = "80"
  }
}

# Register EC2 instance tagets
resource "aws_lb_target_group_attachment" "app" {
  count            = 3
  target_group_arn = aws_lb_target_group.alb_target.arn
  target_id        = element(var.instances, count.index)
  port             = 80
}

# Create ALB Listener on port 80 to redirect to 443
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
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

# Create ALB Listener on port 443
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"

  certificate_arn = var.acm_cert_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_target.arn
  }
}

# Create ALB
resource "aws_lb" "alb" {
  name               = "nginx-app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb-sg.id]
  subnets            = var.frontend_subnet_ids
}

resource "aws_security_group" "alb-sg" {
  vpc_id = var.vpc_id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
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

# Create A Record for the ALB to access with domain name
resource "aws_route53_record" "dns_record" {
  zone_id = data.aws_route53_zone.hzone.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.alb.dns_name
    zone_id                = aws_lb.alb.zone_id
    evaluate_target_health = true
  }
}

