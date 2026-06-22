## creates an Application Load Balancer (ALB) and a target group for the ALB. It also creates a listener for the ALB that forwards traffic to the target group.

# create an alb in the public subnets
resource "aws_lb" "alb" {
  # checkov:skip=CKV2_AWS_28: alb already protected by security group who restricts access to only CloudFront prefix list, and cloudfront is protected by AWS WAF 
  # checkov:skip=CKV_AWS_150: Portofolio project — deletion protection not needed
  # checkov:skip=CKV2_AWS_20: No certificate yet, HTTP only — HTTPS is a future improvement

  name                       = "ALB-${var.environment}"
  internal                   = false # set to false to create an internet-facing ALB that can receive traffic from the internet
  load_balancer_type         = "application"
  security_groups            = [var.alb_sg_id]
  subnets                    = var.public_subnet_ids
  enable_deletion_protection = false # set to false to prevent accidental deletion of the ALB, which is a critical component of the infrastructure and should be protected from accidental deletion
  drop_invalid_header_fields = true  # drop invalid header fields to improve security by preventing malicious requests with malformed headers from reaching the targets
  access_logs {
    bucket  = "${var.environment}-${var.logs_bucket_name}"
    prefix  = "alb-logs"
    enabled = true
  }

  tags = {
    Name        = "ALB-${var.environment}"
    Environment = var.environment
  }

}

# create a target group for the ALB to receive traffic from the listener and forward it to the ECS on port 3000 in the private subnets
resource "aws_lb_target_group" "target" {
  #checkov:skip=CKV_AWS_378: target group use port 3000 which is not a well-known port, and the target group is only accessible from the ALB security group
  name        = "TargetGroup-${var.environment}"
  port        = 3000 # the port on which the target group receives traffic from the ALB, which should match the port defined in the container definition and the port exposed in the Dockerfile
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    path                = "/health" # specify the path for the health check (e.g., the root path of the application)
    interval            = 30        # check every 30 seconds
    timeout             = 5         # consider the target unhealthy if it does not respond within 5 seconds
    healthy_threshold   = 3         # consider the target healthy after 3 consecutive successful health checks
    unhealthy_threshold = 2         # consider the target unhealthy after 2 consecutive failed health checks
    matcher             = "200"     # consider the target healthy if it returns a 200 status code

  }
}

# create a listener for the alb to receive traffic from cdn on port 443 and forward it to the target group
resource "aws_lb_listener" "frontend" {
  #checkov:skip=CKV_AWS_103: in this portfolio project, we are not using an SSL certificate for the ALB, so we will use HTTP on port 80 for simplicity. In a production environment, you should use HTTPS with a valid SSL certificate to secure the traffic between the clients and the ALB.
  #checkov:skip=CKV_AWS_2: No certificate yet, HTTP only — HTTPS is a future improvement

  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"
  #certificate_arn   = var.certificate_arn  uncomment this line and provide the ARN of the SSL certificate to enable HTTPS for the ALB


  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target.arn
  }

}

/* # uncomment this resource to create an HTTP listener that redirects traffic to HTTPS for better security, but make sure to provide the ARN of the SSL certificate in the variable and uncomment the certificate_arn line in the listener resource above
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.alb.arn
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
*/