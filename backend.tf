
terraform {
  backend "s3" {
    bucket         = "dev-app-massar-state"
    key            = "terraform.tfstate"
    region         = "eu-south-1"
    use_lockfile = true # Enables native S3 state locking
    encrypt        = true
  }
}
