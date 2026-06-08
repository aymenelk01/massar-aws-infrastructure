resource "aws_cloudwatch_log_group" "ecs_log_group" {

  # checkov:skip=CKV_AWS_158:Portfolio project- AWS managed encryption acceptable
  name              = "/ecs/massar-${var.environment}"
  retention_in_days = 365

  tags = {
    Name        = "ECSLogGroup-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_log_group" "ecs_exec_log_group" {
  # checkov:skip=CKV_AWS_158:Portfolio project- AWS managed encryption acceptable

  name              = "/ecs/exec/massar-${var.environment}"
  retention_in_days = 7

  tags = {
    Name        = "ECSExecLogGroup-${var.environment}"
    Environment = var.environment
  }
}
