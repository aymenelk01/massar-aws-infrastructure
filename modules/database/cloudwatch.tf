# Create a CloudWatch Log Group for RDS logs
resource "aws_cloudwatch_log_group" "rds_error_logs" {
  name              = "/aws/rds/instance/${var.rds_identifier}/error"
  retention_in_days = 30 # the logs will be saved in CloudWatch for 30 days, after which they will be automatically deleted. 
  #Adjust this value based on your log retention requirements and compliance policies.

  tags = {
    Name        = "RDSLogs-${var.environment}"
    Environment = var.environment
  }

}

# Create a CloudWatch Log Group for RDS slow query logs
resource "aws_cloudwatch_log_group" "rds_slowquery_logs" {
  name              = "/aws/rds/instance/${var.rds_identifier}/slowquery"
  retention_in_days = 30 # the logs will be saved in CloudWatch for 30 days, after which they will be automatically deleted. 
  #Adjust this value based on your log retention requirements and compliance policies.

  tags = {
    Name        = "RDSSlowQueryLogs-${var.environment}"
    Environment = var.environment
  }

}
