

resource "aws_ecs_task_definition" "flyway" {
  family                   = "${var.environment}-flyway-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.flyway_execution_role.arn
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }


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
          value = "jdbc:mysql://${var.aurora_cluster_endpoint}:3306/${var.db_name}?useSSL=true&requireSSL=true&trustServerCertificate=true" # JDBC URL for connecting to the database through the Aurora cluster writer endpoint directly, with SSL mode set to REQUIRED for secure communication and trustServerCertificate set to true to allow connections without validating the server's SSL certificate, which is necessary when using self-signed certificates or when the certificate authority is not recognized by the client.
        }
      ]

      secrets = [
        {
          name      = "FLYWAY_USER"
          valueFrom = "${var.db_password_secret_arn}:username::"
        },
        {
          name      = "FLYWAY_PASSWORD"
          valueFrom = "${var.db_password_secret_arn}:password::"
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
