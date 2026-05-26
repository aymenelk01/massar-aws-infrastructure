# Create a Secrets Manager secret to store the database credentials
resource "aws_secretsmanager_secret" "credential_secret" {
    name = "db-credentials-${var.environment}"
    description = "Secret for RDS database credentials for ${var.environment} environment"
    

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