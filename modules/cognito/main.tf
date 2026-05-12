# This module sets up AWS Cognito for user authentication and management.

# Create a Cognito user pool for the application 
resource "aws_cognito_user_pool" "massar_pool" {
  name = "massar-pool-${var.environment}"

  admin_create_user_config {
    allow_admin_create_user_only = true # only allow administrators to create user accounts, which can help improve security by preventing unauthorized user registration and ensuring that user accounts are created and managed in a controlled manner.
  }

  password_policy {
    minimum_length = 8
    require_lowercase = true
    require_uppercase = true
    require_numbers = true
    require_symbols = false # set to true if you want to require users to include special characters in their passwords, which can help improve password strength and security.
  }

  username_attributes = ["email"] # allow users to sign in with their email address instead of a separate username, which can simplify the login process and improve user experience.

  tags = {
    Name = "MassarUserPool-${var.environment}"
    Environment = var.environment
  }  

}

# Create a user pool client for the Cognito user pool to allow the application to interact with the user pool
resource "aws_cognito_user_pool_client" "massar_client" {
  name = "massar-client-${var.environment}"
  user_pool_id = aws_cognito_user_pool.massar_pool.id

  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH", # allow users to authenticate with username and password to obtain tokens
    /* "ALLOW_USER_SRP_AUTH",*/ # uncomment it to allow users to authenticate with the Secure Remote Password protocol
    "ALLOW_REFRESH_TOKEN_AUTH" # allow users to refresh their authentication tokens to maintain their session
  ]

  generate_secret = false # set to true if you want to generate a client secret for the user pool client, which is required for certain authentication flows (e.g., client credentials flow)

}