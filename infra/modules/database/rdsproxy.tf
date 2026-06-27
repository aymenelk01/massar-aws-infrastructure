# RDS Proxy configuration to optimize database connections and improve performance for the Aurora cluster

resource "aws_iam_role" "rdsproxy_role" {
  name = "massar-rdsproxy-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "rds.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "massar-RDSProxyRole-${var.environment}"
  }
}

resource "aws_iam_role_policy" "rdsproxy_policy" {
  name = "massar-rdsproxy-policy-${var.environment}"
  role = aws_iam_role.rdsproxy_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "rds-db:connect"
        ]
        Resource = [
          "arn:aws:rds-db:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:dbuser:${aws_rds_cluster.aurora.cluster_resource_id}/db_iam_user"
        ]
      }
    ]
  })
}

resource "aws_db_proxy" "writer" {
  name                   = "aurora-proxy-${var.environment}"
  debug_logging          = false # enable debug logging for troubleshooting, but disable it in production for better performance and security and to avoid unnecessary costs
  engine_family          = "MYSQL"
  idle_client_timeout    = 1800 # set the idle client timeout to 30 minutes to close idle connections and free up resources
  require_tls            = true # require TLS for secure communication between the proxy and clients
  role_arn               = aws_iam_role.rdsproxy_role.arn
  vpc_security_group_ids = [var.rdsproxy_sg_id]
  vpc_subnet_ids         = var.private_db_subnet_ids

  # Configure the proxy to use end-to-end IAM database authentication, bypassing Secrets Manager entirely for client database connections.
  default_auth_scheme = "IAM_AUTH"

  tags = {
    Name = "aurora-proxy-${var.environment}"
  }
}

# Create a read-only endpoint for the RDS Proxy to distribute read queries across multiple Aurora reader instances, improving performance and scalability for read-heavy workloads
resource "aws_db_proxy_endpoint" "reader" {
  db_proxy_name          = aws_db_proxy.writer.name
  db_proxy_endpoint_name = "aurora-proxy-reader-${var.environment}"
  vpc_subnet_ids         = var.private_db_subnet_ids
  vpc_security_group_ids = [var.rdsproxy_sg_id]
  target_role            = "READ_ONLY"

  tags = {
    Name = "aurora-proxy-reader-${var.environment}"
  }
}

# Create a default target group for the RDS Proxy with connection pool configuration to optimize database connections and improve performance
resource "aws_db_proxy_default_target_group" "proxy_target_group" {
  db_proxy_name = aws_db_proxy.writer.name

  connection_pool_config {
    connection_borrow_timeout    = 120
    max_connections_percent      = 100
    max_idle_connections_percent = 50
    session_pinning_filters      = ["EXCLUDE_VARIABLE_SETS"]
  }

  lifecycle {
    replace_triggered_by = [aws_db_proxy.writer.id]
  }
}

# create a target for the RDS Proxy to connect to the Aurora cluster
resource "aws_db_proxy_target" "proxy_target" {
  db_proxy_name         = aws_db_proxy.writer.name
  target_group_name     = aws_db_proxy_default_target_group.proxy_target_group.name
  db_cluster_identifier = aws_rds_cluster.aurora.cluster_identifier
}
