resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name              = "/ecs/massar-${var.environment}"
  retention_in_days = 30

  tags = {
    Name        = "ECSLogGroup-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_log_group" "ecs_exec_log_group" {
  name              = "/ecs/exec/massar-${var.environment}"
  retention_in_days = 30

  tags = {
    Name        = "ECSExecLogGroup-${var.environment}"
    Environment = var.environment
  }
}