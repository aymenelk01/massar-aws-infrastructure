# Auto Scaling Target for ECS Service

# This resource defines the auto scaling target for the ECS service, specifying the minimum and maximum number of tasks that should be running based on the desired count defined in the ECS service configuration. It also specifies the scalable dimension and service namespace for the auto scaling configuration, allowing the ECS service to automatically scale up or down based on demand and maintain high availability for the application.
resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = 10
  min_capacity       = 2
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
    target_value = 75
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }

}