
# Application Load Balancer
resource "aws_lb" "app" {
  count = var.enable_application ? 1 : 0

  name               = "phishing-app-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [
    aws_security_group.alb.id
  ]

  subnets = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id
  ]

  tags = {
    Name = "phishing-app-alb"
  }
}

# Group of application servers
resource "aws_lb_target_group" "app" {
  count = var.enable_application ? 1 : 0

  name        = "phishing-app-targets"
  port        = 5000
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.main.id

  health_check {
    enabled             = true
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "phishing-app-targets"
  }
}

# Register both EC2 instances as targets
resource "aws_lb_target_group_attachment" "app" {
  count = var.enable_application ? 2 : 0

  target_group_arn = aws_lb_target_group.app[0].arn
  target_id        = aws_instance.app[count.index].id
  port             = 5000
}

# Receive HTTP requests and forward them to EC2
resource "aws_lb_listener" "http" {
  count = var.enable_application ? 1 : 0

  load_balancer_arn = aws_lb.app[0].arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app[0].arn
  }
}
