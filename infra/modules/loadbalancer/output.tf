# output of the ALB ARN
output "alb_arn" {
    description = "The ARN of the ALB"
    value = aws_lb.alb.arn
}

# output of the ALB DNS name
output "alb_dns_name" {
    description = "The DNS name of the ALB"
    value = aws_lb.alb.dns_name
}

# output of the target group ARN
output "target_group_arn" {
    description = "The ARN of the target group for the ALB"
    value = aws_lb_target_group.target.arn
}

