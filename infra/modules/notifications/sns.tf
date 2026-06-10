
resource "aws_sns_topic" "notifications_topic" {
  name = "${var.environment}-notifications-topic"

  kms_master_key_id = "alias/aws/sns" # Use the default AWS-managed KMS key for SNS encryption

  tags = {
    Name        = "${var.environment}-notifications-topic"
    Environment = var.environment
    Module      = "notifications"
  }
}
