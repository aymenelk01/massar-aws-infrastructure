resource "aws_flow_log" "vpc_flow_log" {
  iam_role_arn         = aws_iam_role.vpcflow_role.arn
  log_destination_type = "cloud-watch-logs"
  log_destination      = aws_cloudwatch_log_group.vpcflow_log_group.arn
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.main.id

  tags = {
    Name        = "VPCFlowLog-${var.environment}"
    Environment = var.environment
    Module      = "vpc"
  }
}
