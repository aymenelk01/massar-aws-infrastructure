# create a dynamodb table for the ec2 application to store session data
resource "aws_dynamodb_table" "session_table" {
  name         = "SessionTable-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "SessionID"

  attribute {
    name = "SessionID"
    type = "S"
  }

  # enable server side encryption for the table
  server_side_encryption {
    enabled = true
  }

  # enable point in time recovery for the table to protect against accidental deletes or updates
  point_in_time_recovery {
    enabled = false # set it to true in a production environment
  }

  # enable TTL to automatically delete expired sessions
  ttl {
    attribute_name = "ExpiresAt"
    enabled        = true
  }


  tags = {
    Name        = "SessionTable-${var.environment}"
    Environment = var.environment
  }
}


# create a dynamodb table for the ec2 application to store the user data
resource "aws_dynamodb_table" "user_table" {
  name         = "UserTable-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "UserID"

  attribute {
    name = "UserID"
    type = "S"
  }

  attribute {
    name = "Email"
    type = "S"
  }

  global_secondary_index {
    name = "EmailIndex"
    key_schema {
      attribute_name = "Email"
      key_type       = "HASH"
    }
    projection_type = "ALL"
  }

  server_side_encryption {
    enabled = true
  }

  point_in_time_recovery {
    enabled = false # set it to true in a production environment
  }



  tags = {
    Name        = "UserTable-${var.environment}"
    Environment = var.environment
  }
}
