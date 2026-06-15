resource "aws_ecr_repository" "massar_repo" {
  # checkov:skip=CKV_AWS_136: Portfolio project- AWS default encryption is sufficient for a portfolio project, so using the default AWS-managed encryption to avoid additional costs from a custom KMS key.
  # checkov:skip=CKV_AWS_51: Tag immutability disabled by design — pipeline pushes both SHA and latest tags. SHA tags provide rollback capability and he requires mutability, while latest tags are used for ease of development and testing, and the lifecycle policy will manage old images to control costs.
  name                 = "ecr-repository-${var.environment}"
  image_tag_mutability = "MUTABLE"

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

# create a lifecycle policy for the ECR repository to automatically clean up old images and manage storage costs, while keeping recent images for rollback safety
resource "aws_ecr_lifecycle_policy" "cleanup_policy" {
  repository = aws_ecr_repository.massar_repo.name

  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Keep only the last 5 images tagged with a Git SHA for rollback safety",
            "selection": {
                "tagStatus": "tagged",
                "tagPatternList": ["sha-*"], 
                "countType": "imageCountMoreThan",
                "countNumber": 5
            },
            "action": {
                "type": "expire"
            }
        },
        {
            "rulePriority": 2,
            "description": "Immediately delete orphaned untagged images to save storage costs",
            "selection": {
                "tagStatus": "untagged",
                "countType": "sinceImagePushed",
                "countUnit": "days",
                "countNumber": 1
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}

# 
resource "aws_ecr_repository" "flyway_repo" {
  # checkov:skip=CKV_AWS_136: Portfolio project- AWS default encryption is sufficient for a portfolio project, so using the default AWS-managed encryption to avoid additional costs from a custom KMS key.
  # checkov:skip=CKV_AWS_51: Tag immutability disabled by design — pipeline pushes both SHA and latest tags. SHA tags provide rollback capability and he requires mutability, while latest tags are used for ease of development and testing, and the lifecycle policy will manage old images to control costs.
  name                 = "flyway-repository-${var.environment}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name        = "ECRFlywayRepository-${var.environment}"
    Environment = var.environment
  }
}