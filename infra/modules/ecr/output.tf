output "ecr_repository_url" {
  description = "The URI of the ECR repository"
  value       = aws_ecr_repository.massar_repo.repository_url

}

output "ecr_repository_arn" {
  description = "The ARN of the ECR repository"
  value       = aws_ecr_repository.massar_repo.arn

}

output "ecr_flyway_repository_url" {
  description = "The URL of the ECR repository for Flyway"
  value       = aws_ecr_repository.flyway_repo.repository_url

}