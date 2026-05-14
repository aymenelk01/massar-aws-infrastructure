# Create an ECS cluster to run the application tasks, enabling container insights for monitoring and troubleshooting purposes, and configuring execute command for remote debugging and management of the tasks
resource "aws_ecs_cluster" "cluster" {
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
resource "aws_ecs_task_definition" "task_definition" {
  family                   = "${var.environment}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_role.arn
  container_definitions = jsonencode([
    {
      name      = "massar-app"
      image     = "${var.ecr_repository_url}:latest"
      cpu       = 256
      memory    = 512
      essential = true

      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]

      environment = [
        { name = "COGNITO_USER_POOL_ID", value = var.user_pool_id },
        { name = "USER_POOL_CLIENT_ID", value = var.user_pool_client_id },
        { name = "ELASTICACHE_ENDPOINT", value = var.elasticache_replication_group_endpoint },
        { name = "RDS_PROXY_ENDPOINT", value = var.rds_proxy_endpoint },
        { name = "DB_NAME", value = var.db_name },
        { name = "ENVIRONMENT", value = var.environment }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs_log_group.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

# Create an ECS Service to run the tasks and manage the desired count of tasks for high availability and scalability
resource "aws_ecs_service" "service" {
  name            = "${var.environment}-service"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.task_definition.arn
  desired_count   = 2 # Set the desired count of tasks to 2 for high availability, but adjust this value based on your application's needs and traffic patterns
  launch_type     = "FARGATE"
  enable_execute_command = true # Enable execute command for remote debugging and management of the tasks, which allows you to run commands in the container without needing to SSH into the underlying EC2 instances, providing a more secure and efficient way to troubleshoot and manage your application tasks


  network_configuration {
    subnets         = var.private_app_subnet_ids
    security_groups = [var.ecs_sg_id]
    assign_public_ip = false # Set to true if you want to assign public IPs to the tasks, but it's recommended to keep it false for better security and use a NAT gateway for outbound internet access if needed
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "massar-app"
    container_port   = 80 # The port on which the container listens for traffic, which should match the port defined in the container definition and the target group configuration
  }

  tags = {
    Name        = "ECSService-${var.environment}"
    Environment = var.environment
  }
  
}