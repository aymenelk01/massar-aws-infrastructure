# Create an ECS cluster to run the application tasks, enabling container insights for monitoring and troubleshooting purposes, and configuring execute command for remote debugging and management of the tasks
resource "aws_ecs_cluster" "cluster" {
  # checkov:skip=CKV_AWS_224: portfolio project; using AWS-managed default encryption for ECS cluster logs to avoid additional costs and complexity of managing custom KMS keys, while still ensuring that logs are encrypted at rest with AWS's default encryption
  name = "${var.environment}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  configuration {
    execute_command_configuration {
      logging = "OVERRIDE"
      log_configuration {
        cloud_watch_encryption_enabled = false # Set to true if you want to encrypt logs in CloudWatch
        cloud_watch_log_group_name     = aws_cloudwatch_log_group.ecs_exec_log_group.name
      }
    }
  }

  tags = {
    Name        = "ECSCluster-${var.environment}"
    Environment = var.environment
  }
}

# Create an ecs task definition for the application, specifying the container image, resource requirements, environment variables, and log configurationuration to send logs to CloudWatch Logs for monitoring and troubleshooting purposes
resource "aws_ecs_task_definition" "app" {
  family                   = "${var.environment}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  


  container_definitions = jsonencode([
    {
      name      = "massar-app"
      image     = "${var.ecr_repository_url}:latest" # Use the latest tag for the container image, but consider using specific version tags for better control and stability in production environments
      cpu       = 256
      memory    = 512
      essential = true
      readonlyRootFilesystem = true # Set the root filesystem to read-only for improved security, which prevents the application from making changes to the underlying filesystem and helps mitigate potential attack vectors that rely on writing to the filesystem

      portMappings = [
        {
          containerPort = 3000 # The port on which the container listens for traffic, which should match the port defined in the target group configuration and the port exposed in the Dockerfile
          hostPort      = 3000 # The port on the host that is mapped to the container port, which should match the port defined in the target group configuration and the port exposed in the Dockerfile
          protocol      = "tcp"
        }
      ]

      environment = [
        { name = "COGNITO_USER_POOL_ID", value = var.user_pool_id },
        { name = "USER_POOL_CLIENT_ID", value = var.user_pool_client_id },
        { name = "ELASTICACHE_ENDPOINT", value = var.elasticache_replication_group_endpoint },
        { name = "RDS_PROXY_ENDPOINT", value = var.rds_proxy_endpoint },
        { name = "DB_NAME", value = var.db_name },
        { name = "SQS_QUEUE_URL", value = var.sqs_queue_url },
        { name = "DB_SECRET_ARN", value = var.db_secret_arn },
        { name = "ENVIRONMENT", value = var.environment },
        { name = "AWS_REGION", value = data.aws_region.current.region }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs_log_group.name
          awslogs-region        = data.aws_region.current.region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

# Create an ECS Service to run the tasks and manage the desired count of tasks for high availability and scalability
resource "aws_ecs_service" "service" {
  name                   = "${var.environment}-service"
  cluster                = aws_ecs_cluster.cluster.id
  task_definition        = aws_ecs_task_definition.app.arn
  desired_count          = 2 # Set the desired count of tasks to 2 for high availability, but adjust this value based on your application's needs and traffic patterns
  launch_type            = "FARGATE"
  enable_execute_command = true # Enable execute command for remote debugging and management of the tasks, which allows you to run commands in the container without needing to SSH into the underlying EC2 instances, providing a more secure and efficient way to troubleshoot and manage your application tasks

  lifecycle {
    ignore_changes = [task_definition] # Ignore changes to the task definition to prevent unnecessary service updates when the task definition is updated, allowing for smoother deployments and minimizing downtime during updates
  }

  network_configuration {
    subnets          = var.private_app_subnet_ids
    security_groups  = [var.ecs_sg_id]
    assign_public_ip = false # Set to true if you want to assign public IPs to the tasks, but it's recommended to keep it false for better security and use a NAT gateway for outbound internet access if needed
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "massar-app"
    container_port   = 3000 # The port on which the container listens for traffic, which should match the port defined in the container definition and the target group configuration
  }

  tags = {
    Name        = "ECSService-${var.environment}"
    Environment = var.environment
  }

}
