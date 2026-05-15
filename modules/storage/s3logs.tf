### create a bucket for the logs
#1. create the bucket
resource "aws_s3_bucket" "logs" {
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
        id = "archive-old-logs"
        status = "Enabled"
    filter {} # apply the rule to all objects in the bucket

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

