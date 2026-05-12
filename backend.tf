/*
terraform {
  backend "s3" {
    bucket         = "dev-aymenelk01-state-files"
    key            = "terraform.tfstate"
    region         = "eu-south-1"
    dynamodb_table = "terraform-lock-dev"
    encrypt        = true
  }
}
*/