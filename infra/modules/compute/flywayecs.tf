

resource "aws_ecs_task_definition" "flyway" {
  family                   = "${var.environment}-flyway-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name                   = "flyway-migration"
      image                  = "${var.ecr_flyway_repository_url}:latest"
      essential              = true
      readonlyRootFilesystem = true # Set to true to enhance security by preventing write access to the root filesystem
      linuxParameters = {
        tmpfs = [
          {
            containerPath = "/tmp"
            size          = 128                                 # Size in MiB for the tmpfs volume, adjust as needed based on the expected temporary storage requirements of the Flyway migration process
            mountOptions  = ["noexec", "nosuid", "nodev", "rw"] # Mount options to enhance security and control the behavior of the tmpfs volume, such as preventing execution of binaries, disallowing setuid and device files, and specifying the size limit for the tmpfs volume
          }
        ]
      }

      environment = [
        {
          name  = "FLYWAY_URL"
          value = "jdbc:mysql://${var.rds_proxy_endpoint}:3306/${var.db_name}?sslMode=REQUIRED" # Set the JDBC URL for the database connection, including the RDS Proxy endpoint, database name, and SSL mode to ensure secure communication between the Flyway migration task and the database, which is essential for protecting sensitive data during the migration process
        }
      ]

      secrets = [
        {
          name      = "FLYWAY_USER"
          valueFrom = "${var.db_secret_arn}:username::"
        },
        {
          name      = "FLYWAY_PASSWORD"
          valueFrom = "${var.db_secret_arn}:password::"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs_flyway_log_group.name
          awslogs-region        = data.aws_region.current.region
          awslogs-stream-prefix = "ecsflyway" # Prefix for the log stream name in CloudWatch Logs, which helps organize and identify logs related to the Flyway migration task, making it easier to monitor and troubleshoot any issues that may arise during the migration process
        }
      }
    }
  ])
}
