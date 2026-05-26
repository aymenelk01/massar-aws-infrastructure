# RDS Proxy configuration to optimize database connections and improve performance for the Aurora cluster
resource "aws_iam_role" "rdsproxy_role" {
    name = "rdsproxy-role-${var.environment}"
    
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
        Name        = "RDSProxyRole-${var.environment}"
        Environment = var.environment
    }
  
}

resource "aws_iam_role_policy" "rdsproxy_policy" {
   name = "rdsproxy-policy-${var.environment}"
   role = aws_iam_role.rdsproxy_role.id
    policy = jsonencode({
         Version = "2012-10-17"
         Statement = [
         {
              Effect = "Allow"
              Action = [
                "secretsmanager:GetSecretValue",
                "secretsmanager:DescribeSecret"
              ]
              Resource = aws_secretsmanager_secret.credential_secret.arn
         }
         ]
    })
}


resource "aws_db_proxy" "proxy" {
  name                   = "aurora-proxy-${var.environment}"
  debug_logging          = false # enable debug logging for troubleshooting, but disable it in production for better performance and security and to avoid unnecessary costs
  engine_family          = "MYSQL"
  idle_client_timeout    = 1800 # set the idle client timeout to 30 minutes to close idle connections and free up resources
  require_tls            = true # require TLS for secure communication between the proxy and clients
  role_arn               = aws_iam_role.rdsproxy_role.arn
  vpc_security_group_ids = [var.rdsproxy_sg_id]
  vpc_subnet_ids         = var.private_db_subnet_ids

  # configure authentication for the RDS Proxy to use the credentials stored in Secrets Manager
  auth {
    auth_scheme = "SECRETS" # use Secrets Manager for authentication to securely manage database credentials and avoid hardcoding them in the application code or configuration files
    description = "Authentication for RDS Proxy using Secrets Manager"
    iam_auth    = "DISABLED" # disable IAM authentication to use only Secrets Manager for authentication, which is more secure and easier to manage for database credentials
    secret_arn  = aws_secretsmanager_secret.credential_secret.arn
  }

  tags = {
    Name = "aurora-proxy-${var.environment}"
    Environment = var.environment
  }
}


# Create a default target group for the RDS Proxy with connection pool configuration to optimize database connections and improve performance
resource "aws_db_proxy_default_target_group" "proxy_target_group" {
  db_proxy_name = aws_db_proxy.proxy.name

  connection_pool_config {
    connection_borrow_timeout    = 120
    max_connections_percent      = 100
    max_idle_connections_percent = 50
    session_pinning_filters      = ["EXCLUDE_VARIABLE_SETS"]
  }

  lifecycle {
    replace_triggered_by = [aws_db_proxy.proxy.id]
  }
  
}

# create a target for the RDS Proxy to connect to the Aurora cluster
resource "aws_db_proxy_target" "proxy_target" {
  db_proxy_name         = aws_db_proxy.proxy.name
  target_group_name     = aws_db_proxy_default_target_group.proxy_target_group.name
  db_cluster_identifier = aws_rds_cluster.aurora.cluster_identifier
}

