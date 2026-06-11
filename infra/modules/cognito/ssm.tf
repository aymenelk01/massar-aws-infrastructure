resource "aws_ssm_parameter" "cognito_user_pool_id" {
  #checkov:skip=CKV2_AWS_34: Cognito IDs are client-side identifiers that are public by design no need to be encrypted

  name  = "/massar/${var.environment}/cognito_user_pool_id"
  type  = "String"
  value = aws_cognito_user_pool.massar_pool.id
}

resource "aws_ssm_parameter" "cognito_client_id" {
  #checkov:skip=CKV2_AWS_34: Cognito IDs are client-side identifiers that are public by design no need to be encrypted
  name  = "/massar/${var.environment}/cognito_client_id"
  type  = "String"
  value = aws_cognito_user_pool_client.massar_client.id
}
