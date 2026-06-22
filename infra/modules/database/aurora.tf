
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "db-subnet-group-${var.environment}"
  subnet_ids = var.private_db_subnet_ids
  tags = {
    Name        = "DBSubnetGroup-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_rds_cluster" "aurora" {
  # checkov:skip=CKV_AWS_162: Portfolio project- iam auth defferred - documented in README as a future enhancement and not critical for a portfolio project.
  # checkov:skip=CKV_AWS_139: Portfolio project- deletion protection set to false because it's a non-production environment and allows for easier cleanup without manual intervention.
  # checkov:skip=CKV_AWS_313: Portfolio project- copy tags to snapshots set to false because it's not necessary for a portfolio project and can be skipped to avoid additional costs from snapshot storage.
  # checkov:skip=CKV_AWS_327: Portfolio project- using default AWS-managed encryption to maintain $0.00 cost instead of a $1/mo paid custom KMS key
  # checkov:skip=CKV_AWS_326: Portfolio project- uses modern Aurora MySQL v3 (MySQL 8.0). Backtracking is a legacy feature only supported on v2 and is skipped to avoid deployment errors.
  # checkov:skip=CKV2_AWS_8: Portfolio project- relying on native Aurora automated backups it's sufficient for a portfolio project.
  cluster_identifier                  = "aurora-cluster-${var.environment}"
  engine                              = "aurora-mysql"
  engine_mode                         = "provisioned"
  engine_version                      = "8.0.mysql_aurora.3.12.0"
  database_name                       = var.db_name
  master_username                     = var.db_username
  manage_master_user_password         = true
  storage_encrypted                   = true
  vpc_security_group_ids              = [var.aurora_sg_id]
  db_subnet_group_name                = aws_db_subnet_group.db_subnet_group.name
  enabled_cloudwatch_logs_exports     = ["audit", "error", "slowquery"]
  deletion_protection                 = false
  copy_tags_to_snapshot               = false
  skip_final_snapshot                 = true # Skip final snapshot to avoid additional costs in a portfolio project, as the database is not critical and can be easily recreated if needed. This is acceptable for a non-production environment where data persistence is not a concern.
  iam_database_authentication_enabled = true

  depends_on = [
    aws_cloudwatch_log_group.aurora_error_logs,
    aws_cloudwatch_log_group.aurora_slowquery_logs
  ]


  serverlessv2_scaling_configuration {
    max_capacity = 64
    min_capacity = 0.5
  }

  tags = {
    Name        = "AuroraCluster-${var.environment}"
    Environment = var.environment
  }
}

# Create a RDS instance for the Aurora cluster, using the serverless v2 configuration for on-demand scaling based on workload demands
resource "aws_rds_cluster_instance" "aurora_instance" {
  # checkov:skip=CKV_AWS_118: Portfolio project- Enhanced monitoring is disabled to insulate the portfolio project from operational metrics fees.
  # checkov:skip=CKV_AWS_353: Portfolio project- Performance insights are bypassed to avoid additional costs, which is acceptable for a portfolio project.
  cluster_identifier         = aws_rds_cluster.aurora.cluster_identifier
  identifier                 = "aurora-instance-${var.environment}"
  instance_class             = "db.serverless"
  engine                     = aws_rds_cluster.aurora.engine
  engine_version             = aws_rds_cluster.aurora.engine_version
  auto_minor_version_upgrade = true # Enable automatic minor version upgrades to ensure the database instance receives important security patches and updates without manual intervention, which is suitable for a portfolio project and helps maintain security without additional operational overhead.

  tags = {
    Name        = "AuroraInstance-${var.environment}"
    Environment = var.environment
  }
}
