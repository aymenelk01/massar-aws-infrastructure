resource "aws_appautoscaling_target" "aurora_reader" {
  service_namespace  = "rds"
  resource_id        = "cluster:${aws_rds_cluster.aurora.id}"
  scalable_dimension = "rds:cluster:ReadReplicaCount"
  min_capacity       = 1 # static reader above always exists, this is the floor Auto Scaling maintains
  max_capacity       = 3

  depends_on = [aws_rds_cluster_instance.aurora_reader]
}

resource "aws_appautoscaling_policy" "aurora_reader_cpu" {
  name               = "aurora-reader-cpu-${var.environment}"
  policy_type        = "TargetTrackingScaling"
  service_namespace  = aws_appautoscaling_target.aurora_reader.service_namespace
  resource_id        = aws_appautoscaling_target.aurora_reader.resource_id
  scalable_dimension = aws_appautoscaling_target.aurora_reader.scalable_dimension

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "RDSReaderAverageCPUUtilization"
    }

    target_value       = 70
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

# Pre-warm before Bac results
resource "aws_appautoscaling_scheduled_action" "aurora_spike" {
  name               = "aurora-bac-results-spike"
  service_namespace  = aws_appautoscaling_target.aurora_reader.service_namespace
  resource_id        = aws_appautoscaling_target.aurora_reader.resource_id
  scalable_dimension = aws_appautoscaling_target.aurora_reader.scalable_dimension
  schedule           = "cron(0 23 14 7 ? *)" # July 15 00:00 Morocco time

  scalable_target_action {
    min_capacity = 3
    max_capacity = 5
  }
}

# Back to normal after spike
resource "aws_appautoscaling_scheduled_action" "aurora_post_spike" {
  name               = "aurora-bac-results-post-spike"
  service_namespace  = aws_appautoscaling_target.aurora_reader.service_namespace
  resource_id        = aws_appautoscaling_target.aurora_reader.resource_id
  scalable_dimension = aws_appautoscaling_target.aurora_reader.scalable_dimension
  schedule           = "cron(0 23 16 7 ? *)" # July 17 00:00 Morocco time

  scalable_target_action {
    min_capacity = 1
    max_capacity = 3
  }
}