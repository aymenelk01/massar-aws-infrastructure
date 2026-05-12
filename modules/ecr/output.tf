output "ecr_repository_url" {
    description = "The URI of the ECR repository"
    value       = aws_ecr_repository.massar_repo.repository_url
  
}