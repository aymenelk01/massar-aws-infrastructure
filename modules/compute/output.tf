output "ecs_task_arn" {
    description = "The ARN of the ECS task definition"
    value       = aws_ecs_task_definition.app.arn
}

output "ecs_task_family" {
    description = "The family of the ECS task definition"
    value       = aws_ecs_task_definition.app.family
}

