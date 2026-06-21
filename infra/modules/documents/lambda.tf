# This file defines the automated AWS Lambda function and fpdf2 layer using the official community module.

# 1. THE COMMUNITY MODULE HANDLES ZIP PACKAGING, DEPENDENCIES, LOG GROUPS, AND THE FUNCTION LAYERS
module "diploma_generator_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 7.0"

  # checkov:skip=CKV_TF_1:Using public registry references for portfolio grouping
  # checkov:skip=CKV_TF_2:Using public registry references for portfolio grouping

  function_name = "${var.environment}-diploma-generator"
  description   = "Generates Moroccan Baccalaureate diplomas using fpdf2 script layers"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.12"
  timeout       = var.lambda_timeout
  memory_size   = var.lambda_memory_size

  # 2. POINT THE MODULE TO YOUR SRC FOLDER AND TURN ON PIP AUTOMATION
  source_path = [
    {
      path             = "${path.module}/src"
      pip_requirements = true # Module reads src/requirements.txt and installs fpdf2 automatically!
    }
  ]

  # 3. LINK YOUR EXISTING IAM ROLE
  lambda_role = aws_iam_role.lambda_role.arn

  # 4. ENVIRONMENT SETTINGS
  environment_variables = {
    DOCUMENTS_BUCKET_NAME = var.documents_bucket_name
  }

  # 5. CHECOV COMPLIANCE OVERRIDES MAPPED BY THE COMMUNITY WRAPPER
  create_async_event_config = false
  attach_network_policy     = false # Keeps it out of a VPC to prevent cold-start delays

  tags = {
    Name        = "${var.environment}-diploma-generator"
    Environment = var.environment
    Module      = "documents"
  }
}

# 6. CONNECT THE EVENT SOURCE MAPPING TO THE GENERATED OUTPUT FUNCTION NAME
resource "aws_lambda_event_source_mapping" "sqs_event_source" {
  event_source_arn = aws_sqs_queue.main.arn
  function_name    = module.diploma_generator_lambda.lambda_function_arn # Fetches ARN dynamically from module outputs
  batch_size       = var.batch_size
  enabled          = true
}
