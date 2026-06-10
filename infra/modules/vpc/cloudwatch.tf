
resource "aws_cloudwatch_log_group" "vpcflow_log_group" {
  #checkov:skip=CKV_AWS_338:VPC Flow Logs retention set to 7 days — flow logs generate high data volume compared to application logs, and extended retention would significantly increase CloudWatch costs for a portfolio project. 365-day retention is recommended for production environments
  # checkov:skip=CKV_AWS_158: Portfolio porject- AWS default encryption is sufficient for a portfolio project, so using the default AWS-managed encryption to avoid additional costs from a custom KMS key.
  name              = "/aws/vpc/flow-logs/${var.environment}"
  retention_in_days = 7 # the logs will be saved in CloudWatch for 7 days, after which they will be automatically deleted.
  #Adjust this value based on your log retention requirements and compliance policies.
  tags = {
    Name        = "${var.environment}-vpc-flow-log-group"
    Environment = var.environment
    Module      = "vpc"
  }
}