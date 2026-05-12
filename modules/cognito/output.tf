
output "user_pool_id" {
    description = "The ID of the Cognito User Pool"
    value       = aws_cognito_user_pool.massar_pool.id
  
}

output "user_pool_client_id" {
    description = "The ID of the Cognito User Pool Client"
    value       = aws_cognito_user_pool_client.massar_client.id
  
}