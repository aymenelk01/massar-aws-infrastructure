output "ecs_task_arn" {
    description = "The ARN of the ECS task definition"
    value       = aws_ecs_task_definition.app.arn
}

output "ecs_task_family" {
    description = "The family of the ECS task definition"
    value       = aws_ecs_task_definition.app.family
}

output "ecs_cluster_arn" {
    description = "The ARN of the ECS cluster"
    value       = aws_ecs_cluster.cluster.arn
}

output "ecs_service_arn" {
    description = "The ARN of the ECS service"
    value       = aws_ecs_service.service.arn
}

output "iam_role_execution_arn" {
    description = "The ARN of the IAM role for ECS execution"
    value       = aws_iam_role.ecs_task_execution_role.arn
}

output "iam_role_task_arn" {
    description = "The ARN of the IAM role for ECS tasks"
    value       = aws_iam_role.ecs_task_role.arn
}