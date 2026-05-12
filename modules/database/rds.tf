#1 tells rds what subnets to use for the database
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "${var.environment}-db-subnet-group"
  subnet_ids = var.private_db_subnet_ids

  tags = {
    Name        = "${var.environment}-db-subnet-group"
    Environment = var.environment
  }
}

#2 creates the RDS instance
resource "aws_db_instance" "db_instance" {
  identifier                      = var.rds_identifier
  allocated_storage               = var.allocated_storage
  engine                          = var.db_engine
  engine_version                  = "8.0"
  instance_class                  = var.instance_class
  db_name                         = "${var.environment}_db"
  username                        = var.db_username
  password                        = var.db_password
  db_subnet_group_name            = aws_db_subnet_group.db_subnet_group.name
  skip_final_snapshot             = true
  multi_az                        = false # Set to true for production environments so that the database is replicated across multiple availability zones for high availability
  vpc_security_group_ids          = [var.rds_sg_id]
  publicly_accessible             = false                                     # Set to true if you want to allow public access to the database, but it's recommended to keep it false for security reasons
  enabled_cloudwatch_logs_exports = ["error", "slowquery"]                    # Enable CloudWatch Logs exports for RDS to capture error and slow query logs for monitoring and troubleshooting purposes
  parameter_group_name            = aws_db_parameter_group.rds_paramater.name # Associate the custom parameter group with the RDS instance to apply the specified database parameters for performance optimization and monitoring
  
  depends_on = [
    aws_cloudwatch_log_group.rds_error_logs,
    aws_cloudwatch_log_group.rds_slowquery_logs
  ] # Ensure that the CloudWatch Log Groups for RDS error and slow query logs are created before creating the RDS instance to avoid any dependency issues when enabling CloudWatch Logs exports for RDS
  
  tags = {
    Name        = "${var.environment}-db-instance"
    Environment = var.environment
  }
}

# create a parameter group for the RDS instance to enable slow query logging and set the long query time threshold for performance monitoring and optimization
resource "aws_db_parameter_group" "rds_paramater" {
  name        = "${var.environment}-db-parameter-group"
  family      = "mysql8.0"
  description = "Custom parameter group for RDS instance"

  parameter {
    name  = "slow_query_log"
    value = "1"
  }

  parameter {
    name  = "long_query_time"
    value = "0.5"
  }

  tags = {
    Name        = "${var.environment}-db-parameter-group"
    Environment = var.environment
  }

}
