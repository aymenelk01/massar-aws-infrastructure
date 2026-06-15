resource "aws_cloudwatch_log_group" "ecs_log_group" {
  # checkov:skip=CKV_AWS_338:Portfolio project optimized for cost insulation. Retaining logs for 1 year exceeds free tier limits.
  # checkov:skip=CKV_AWS_158:Portfolio project- AWS managed encryption acceptable
  name              = "/ecs/massar-${var.environment}"
  retention_in_days = 7

  tags = {
    Name        = "ECSLogGroup-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_log_group" "ecs_exec_log_group" {
  # checkov:skip=CKV_AWS_338:Portfolio project optimized for cost insulation. Retaining logs for 1 year exceeds free tier limits.
  # checkov:skip=CKV_AWS_158:Portfolio project- AWS managed encryption acceptable

  name              = "/ecs/exec/massar-${var.environment}"
  retention_in_days = 7

  tags = {
    Name        = "ECSExecLogGroup-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_log_group" "ecs_flyway_log_group" {
  # checkov:skip=CKV_AWS_338:Portfolio project optimized for cost insulation. Retaining logs for 1 year exceeds free tier limits.
  # checkov:skip=CKV_AWS_158:Portfolio project- AWS managed encryption acceptable

  name              = "/ecs/flyway/massar-${var.environment}"
  retention_in_days = 7

  tags = {
    Name        = "ECSFlywayLogGroup-${var.environment}"
    Environment = var.environment
  }
}
