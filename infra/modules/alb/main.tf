########################################
# Application Load Balancer (ALB)
########################################

resource "aws_lb" "this" {
  name               = var.name
  internal           = var.internal
  load_balancer_type = "application"

  security_groups = [var.alb_sg_id]
  subnets         = var.public_subnet_ids

  idle_timeout = var.idle_timeout

  tags = merge(
    { Name = var.name },
    var.tags
  )
}

########################################
# Target Group
########################################

resource "aws_lb_target_group" "this" {
  name        = "${var.name}-tg"
  port        = var.target_port
  protocol    = var.target_protocol
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    interval            = 30
    protocol            = var.target_protocol
    path                = var.health_check_path
    matcher             = "200"
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = merge(
    { Name = "${var.name}-tg" },
    var.tags
  )
}

########################################
# Listener
########################################

resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.this.arn
  port              = var.listener_port
  protocol          = var.listener_protocol

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

########################################
# Target Group Attachment (EC2)
########################################

resource "aws_lb_target_group_attachment" "attach" {
  count = var.attach_target ? 1 : 0

  target_group_arn = aws_lb_target_group.this.arn
  target_id        = var.target_id
  port             = var.target_port
}
