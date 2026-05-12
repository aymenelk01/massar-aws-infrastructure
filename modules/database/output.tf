# output of RDS instance details

output "db_instance_name" {
    description = "The name of the RDS instance"
    value       = aws_db_instance.db_instance.db_name
}

output "db_instance_endpoint" {
    description = "The endpoint of the RDS instance"
    value       = aws_db_instance.db_instance.endpoint
}

output "db_instance_arn" {
    description = "The ARN of the RDS instance"
    value       = aws_db_instance.db_instance.arn
}

output "db_instance_id" {
    description = "The ID of the RDS instance"
    value       = aws_db_instance.db_instance.id
}

output "db_subnet_group_name" {
    description = "The name of the DB subnet group"
    value       = aws_db_subnet_group.db_subnet_group.name
}

output "db_subnet_group_arn" {
    description = "The ARN of the DB subnet group"
    value       = aws_db_subnet_group.db_subnet_group.arn
}

output "db_subnet_group_id" {
    description = "The ID of the DB subnet group"
    value       = aws_db_subnet_group.db_subnet_group.id
}

output "db_instance_status" {
    description = "The status of the RDS instance"
    value       = aws_db_instance.db_instance.status
}


output "dynamodb_session_table_arn" {
    description = "The ARN of the DynamoDB session table"
    value       = aws_dynamodb_table.session_table.arn
}

output "dynamodb_user_table_arn" {
    description = "The ARN of the DynamoDB table"
    value       = aws_dynamodb_table.user_table.arn
}