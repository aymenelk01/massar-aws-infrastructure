
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "db-subnet-group-${var.environment}"
  subnet_ids = var.private_db_subnet_ids
  tags = {
    Name        = "DBSubnetGroup-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_rds_cluster" "aurora" {
  cluster_identifier          = "aurora-cluster-${var.environment}"
  engine                      = "aurora-mysql"
  engine_mode                 = "provisioned"
  engine_version              = "8.0.mysql_aurora.3.12.0"
  database_name               = "massardb"
  master_username             = var.db_username
  master_password             = var.db_password
  storage_encrypted           = true
  vpc_security_group_ids      = [var.aurora_sg_id]
  db_subnet_group_name        = aws_db_subnet_group.db_subnet_group.name


  serverlessv2_scaling_configuration {
    max_capacity             = 64
    min_capacity             = 0.5
  }

  tags = {
    Name        = "AuroraCluster-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_rds_cluster_instance" "aurora_instance" {
  cluster_identifier = aws_rds_cluster.aurora.cluster_identifier
  identifier         = "aurora-instance-${var.environment}"
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.aurora.engine
  engine_version     = aws_rds_cluster.aurora.engine_version

  tags = {
    Name        = "AuroraInstance-${var.environment}"
    Environment = var.environment
  }
}
