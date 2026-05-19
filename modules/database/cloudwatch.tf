# Create a CloudWatch Log Group for RDS logs
resource "aws_cloudwatch_log_group" "aurora_error_logs" {
  name              = "/aws/rds/cluster/aurora-cluster-${var.environment}/error"
  
  retention_in_days = 30 # the logs will be saved in CloudWatch for 30 days, after which they will be automatically deleted. 
  #Adjust this value based on your log retention requirements and compliance policies.

  tags = {
    Name        = "AuroraErrorLogs-${var.environment}"
    Environment = var.environment
  }

}

# Create a CloudWatch Log Group for RDS slow query logs
resource "aws_cloudwatch_log_group" "aurora_slowquery_logs" {
  name              = "/aws/rds/cluster/aurora-cluster-${var.environment}/slowquery"
  retention_in_days = 30 # the logs will be saved in CloudWatch for 30 days, after which they will be automatically deleted. 
  #Adjust this value based on your log retention requirements and compliance policies.

  tags = {
    Name        = "AuroraSlowQueryLogs-${var.environment}"
    Environment = var.environment
  }

}
