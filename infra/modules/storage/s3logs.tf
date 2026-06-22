### create a bucket for the logs
#1. create the bucket
resource "aws_s3_bucket" "logs" {
  #checkov:skip=CKV_AWS_21:Versioning not required — log files are append-only and do not need point-in-time recovery. Enabling versioning would double storage costs with no operational benefit   
  #checkov:skip=CKV_AWS_18:Access logging not enabled on the logs bucket — enabling it would require a separate bucket to receive logs of the logs bucket, creating unnecessary complexity with no security benefit
  #checkov:skip=CKV_AWS_144:Cross-region replication not required — portfolio project, no DR requirements
  #checkov:skip=CKV_AWS_145: Portfolio project- AWS default encryption is sufficient for a portfolio project, so using the default AWS-managed encryption to avoid additional costs from a custom KMS key.
  #checkov:skip=CKV2_AWS_62:S3 event notifications not required — no application logic depends on reacting to S3 object events

  bucket = "${var.environment}-${var.logs_bucket_name}"

  lifecycle {
    prevent_destroy = false # set to true to prevent accidental deletion of the bucket
  }

  tags = {
    Environment = var.environment
    Name        = "${var.environment}-alb-logs-${var.logs_bucket_name}"
  }
}


#2. encrypt the bucket using the default AWS S3 encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "logs_encryption" {
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
#3. create a bucket policy to block public access to the logs
resource "aws_s3_bucket_public_access_block" "logs_public_access" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


#5. create a lifecycle rule to archive the logs to standard_ia after 30 days, move them to glacier after 90 days, and delete them after 365 days
resource "aws_s3_bucket_lifecycle_configuration" "logs_lifecycle" {
  bucket = aws_s3_bucket.logs.id


  rule {
    id     = "archive-old-logs"
    status = "Enabled"
    filter {} # apply the rule to all objects in the bucket

    abort_incomplete_multipart_upload {
      days_after_initiation = 3
    }

    # move the logs to standard_ia after 30 days
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    # move the logs to glacier after 90 days
    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    # delete the logs after 365 days
    expiration {
      days = 365
    }
  }

}

