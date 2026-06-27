# Auto Scaling Target for ECS Service

# Normal days 
resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = 7
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.cluster.name}/${aws_ecs_service.service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

}

resource "aws_appautoscaling_policy" "ecs_scaling_policy" {
  name               = "${var.environment}-scaling-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value       = 75  # scale out when average CPU across all tasks exceeds 75%
    scale_in_cooldown  = 300 # wait 5 min before scaling in — prevents flapping
    scale_out_cooldown = 60  # react fast on scale out — users are waiting
  }

}

# July 15 00:00 Morocco time (July 14 23:00 UTC) — Bac results go live create 8 taskes and scale up to 25 tasks to handle the spike in traffic and ensure that the application can handle the increased load during this period, providing a better user experience and preventing service degradation or downtime.
resource "aws_appautoscaling_scheduled_action" "bac_results_spike" {
  name               = "bac-results-spike"
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  schedule           = "cron(0 23 14 7 ? *)" # July 14 23:00

  scalable_target_action {
    min_capacity = 8
    max_capacity = 25
  }

}

# July 17 00:00 Morocco time (July 16 23:00 UTC) — back to normal minimzing the tasks to 1 and scaling up to 7 tasks to ensure that the application can handle normal traffic levels while minimizing resource usage and costs, providing a better balance between performance and cost efficiency.
resource "aws_appautoscaling_scheduled_action" "bac_results_post_spike" {
  name               = "bac-results-post-spike"
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  schedule           = "cron(0 23 16 7 ? *)"

  scalable_target_action {
    min_capacity = 1
    max_capacity = 7
  }
}
