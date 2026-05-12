## creates an Application Load Balancer (ALB) and a target group for the ALB. It also creates a listener for the ALB that forwards traffic to the target group.

# create an alb in the public subnets
resource "aws_lb" "alb" {
  name               = "ALB-${var.environment}"
  internal           = false # set to false to create an internet-facing ALB that can receive traffic from the internet
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids

  access_logs {
    bucket  = var.logs_bucket_name
    prefix  = "alb-logs"
    enabled = true
  }

  tags = {
    Name = "ALB-${var.environment}"
  }

}

# create a target group for the ALB
resource "aws_lb_target_group" "target" {
  name        = "TargetGroup-${var.environment}"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id # specify the VPC for the target group to ensure that the ALB can route traffic to the EC2 instances in the private subnets 
  target_type = "instance"

  health_check {
    enabled             = true
    path                = "/" # specify the path for the health check (e.g., the root path of the application)
    interval            = 30 # check every 30 seconds
    timeout             = 5 # consider the target unhealthy if it does not respond within 5 seconds
    healthy_threshold   = 3 # consider the target healthy after 3 consecutive successful health checks
    unhealthy_threshold = 2 # consider the target unhealthy after 2 consecutive failed health checks
    matcher             = "200" # consider the target healthy if it returns a 200 status code

  }
}

# create a listener for the ALB
resource "aws_lb_listener" "frontend" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target.arn
  }

}

