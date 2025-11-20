resource "aws_lb" "app_alb" {
  name               = "zihao-app-alb"
  internal           = false # Internet-facing ALB
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]

  # Your real Public Subnets
  subnets = [
    "subnet-0a05dfbfa9b02eb45", # ap-southeast-2a public subnet
    "subnet-044bb7e2c10d0b1ee"  # ap-southeast-2c public subnet
  ]

  idle_timeout = 60

  tags = {
    Name    = "zihao-app-alb"
    Project = "DevOps"
    Owner   = "ZiHao"
  }
}

resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Allow HTTP from the Internet"
  vpc_id      = var.vpc_id

  # Allow Internet to access ALB on port 80
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound (required for ALB)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb-sg"
  }
}

resource "aws_lb_target_group" "app_tg" {
  name        = "zihao-app-tg"
  port        = 3000
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = var.vpc_id

  health_check {
    enabled             = true
    interval            = 30
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200"
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = {
    Name = "zihao-app-tg"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

resource "aws_lb_target_group_attachment" "ec2_attach" {
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = aws_instance.terraform_ec2.id
  port             = 3000
}