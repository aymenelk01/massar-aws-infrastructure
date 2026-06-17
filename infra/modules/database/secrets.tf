# Create a Secrets Manager secret to store the database credentials
resource "aws_secretsmanager_secret" "credential_secret" {
  # checkov:skip=CKV2_AWS_57: Portfolio project- not enabling rotation for the database credentials secret to avoid additional complexity and costs associated with Lambda functions for rotation, which is acceptable for a portfolio project.
  # checkov:skip=CKV_AWS_149: Portfolio project- AWS default encryption is sufficient for a portfolio project, so using the default AWS-managed encryption to avoid additional costs from a custom KMS key.
    name = "db-credentials-${var.environment}"
    description = "Secret for RDS database credentials for ${var.environment} environment"
    recovery_window_in_days = 0 # Forces immediate deletion when run terraform destroy, which is acceptable for a portfolio project
    

    tags = {
        Name = "DBCredentialsSecret-${var.environment}"
        Environment = var.environment
    }
}

# Store the database credentials in the secret as a JSON string
resource "aws_secretsmanager_secret_version" "credential_secret_version" {
    secret_id     = aws_secretsmanager_secret.credential_secret.id
    secret_string = jsonencode({
        username = var.db_username
        password = var.db_password
    })
}