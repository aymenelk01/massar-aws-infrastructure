###1. create a bucket for the static files
# create the bucket
resource "aws_s3_bucket" "static_files" {
  # checkov:skip=CKV_AWS_21:Versioning not required — static files are managed via GitHub and redeployed by pipeline on every push. Recovery does not depend on S3 versioning
  #checkov:skip=CKV2_AWS_62:S3 event notifications not required — no application logic depends on reacting to S3 object events
  #checkov:skip=CKV_AWS_144:Cross-region replication not required — portfolio project, no DR requirements
  #checkov:skip=CKV_AWS_145: Portfolio project- AWS default encryption is sufficient for a portfolio project, so using the default AWS-managed encryption to avoid additional costs from a custom KMS key.

  bucket = "${var.environment}-${var.static_bucket_name}"
  force_destroy = true # since this is a portfolio project, we can allow force deletion of the bucket to avoid manual cleanup and reduce operational overhead, not recommended for production environments where static files are critical for application functionality, but acceptable for a non-production environment where static files can be easily recreated if needed.


  lifecycle {
    prevent_destroy = false # set to true to prevent accidental deletion of the bucket
  }



  tags = {
    Environment = var.environment
    Name        = "${var.environment}-static-files-${var.static_bucket_name}"
  }
}

# encrypt the bucket using the default AWS S3 encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "static_files_encryption" {
  bucket = aws_s3_bucket.static_files.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# create a bucket policy to block public access to the static files
resource "aws_s3_bucket_public_access_block" "static_files_public_access" {
  bucket = aws_s3_bucket.static_files.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


# configure the bucket to store the logs from the state files bucket
resource "aws_s3_bucket_logging" "static_files" {
  bucket        = aws_s3_bucket.static_files.id
  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "staticbucketlog/"
}


# create a lifecycle rule to abort incomplete multipart uploads after 3 days to clean up any failed deployments that may leave behind incomplete uploads
resource "aws_s3_bucket_lifecycle_configuration" "static_lifecycle" {
  bucket = aws_s3_bucket.static_files.id

  rule {
    id     = "clean-up-failed-deployments-only"
    status = "Enabled"

    # Automatically delete hidden, broken upload pieces after 3 days.
    abort_incomplete_multipart_upload {
      days_after_initiation = 3
    }
  }
}
