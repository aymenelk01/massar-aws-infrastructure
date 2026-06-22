# Create a CloudWatch Log Group for RDS logs
resource "aws_cloudwatch_log_group" "aurora_error_logs" {
  # checkov:skip=CKV_AWS_158:Default AWS managed encryption is sufficient for this portfolio project. Avoids customer-managed KMS key costs.
  # checkov:skip=CKV_AWS_338:Portfolio project optimized for cost insulation. Retaining logs for 1 year exceeds free tier limits.

  name = "/aws/rds/cluster/aurora-cluster-${var.environment}/error"

  retention_in_days = 7 # the logs will be saved in CloudWatch for 7 days, after which they will be automatically deleted. Adjust this value based on your log retention requirements and compliance policies.

  tags = {
    Name        = "AuroraErrorLogs-${var.environment}"
    Environment = var.environment
  }

}

# Create a CloudWatch Log Group for RDS slow query logs to monitor and troubleshoot performance issues by analyzing slow queries, which can help identify bottlenecks and optimize database performance, while ensuring that logs are retained for a reasonable period to balance between troubleshooting needs and cost management.
resource "aws_cloudwatch_log_group" "aurora_slowquery_logs" {
  # checkov:skip=CKV_AWS_158:Default AWS managed encryption is sufficient for this portfolio project. Avoids customer-managed KMS key costs.
  # checkov:skip=CKV_AWS_338:Portfolio project optimized for cost insulation. Retaining logs for 1 year exceeds free tier limits.

  name              = "/aws/rds/cluster/aurora-cluster-${var.environment}/slowquery"
  retention_in_days = 7 # the logs will be saved in CloudWatch for 7 days, after which they will be automatically deleted. 
  #Adjust this value based on your log retention requirements and compliance policies.

  tags = {
    Name        = "AuroraSlowQueryLogs-${var.environment}"
    Environment = var.environment
  }

}
