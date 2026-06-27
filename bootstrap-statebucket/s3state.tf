### create bucket for the state files
#1. create the bucket
resource "aws_s3_bucket" "state_files" {
  #checkov:skip=CKV2_AWS_61:Lifecycle policy not required on state bucket — Terraform state files require reliable access to all versions for rollback and recovery. A lifecycle policy risks transitioning or deleting state versions needed for disaster recovery
  #checkov:skip=CKV_AWS_144:Cross-region replication not required — portfolio project, no DR requirements
  #checkov:skip=CKV_AWS_145: Portfolio project- AWS default encryption is sufficient for a portfolio project, so using the default AWS-managed encryption to avoid additional costs from a custom KMS key.
  #checkov:skip=CKV2_AWS_62:S3 event notifications not required — no application logic depends on reacting to S3 object events

  bucket = "${var.state_bucket_name}"
  force_destroy = true # since this is a portfolio project, we can allow force deletion of the bucket to avoid manual cleanup and reduce operational overhead, not recommended for production environments where state files are critical for disaster recovery and rollback, but acceptable for a non-production environment where state files can be easily recreated if needed.

  lifecycle {
    prevent_destroy = false # set to true to prevent accidental deletion of the bucket
  }

  tags = {
    Environment = var.environment
    Name        = "${var.environment}-state-files-${var.state_bucket_name}"
  }
}

# enable versioning for the bucket to protect against accidental overwrites or deletions of the state files
resource "aws_s3_bucket_versioning" "state_files_versioning" {
  bucket = aws_s3_bucket.state_files.id
  versioning_configuration {
    status = "Enabled"
  }
}
# encrypt the bucket using the default AWS S3 encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "state_files_encryption" {
  bucket = aws_s3_bucket.state_files.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state_files_public_access" {
  bucket = aws_s3_bucket.state_files.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
