resource "aws_ecr_repository" "massar_repo" {
  name                 = "ecr-repo-${var.environment}"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name        = "ECRRepository-${var.environment}"
    Environment = var.environment
  }
}