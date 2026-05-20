
resource "aws_sns_topic" "notifications_topic" {
  name = "${var.environment}-notifications-topic"

  tags = {
    Name        = "${var.environment}-notifications-topic"
    Environment = var.environment
    Module      = "notifications"
  }
}
