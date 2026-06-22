###1. create a bucket for the documents files
# create the bucket
resource "aws_s3_bucket" "documents_files" {
  #checkov:skip=CKV_AWS_144:Cross-region replication not required — portfolio project, no DR requirements
  #checkov:skip=CKV2_AWS_62:S3 event notifications not required — no application logic depends on reacting to S3 object events
  #checkov:skip=CKV_AWS_145: Portfolio project- AWS default encryption is sufficient for a portfolio project, so using the default AWS-managed encryption to avoid additional costs from a custom KMS key.
  bucket = "${var.environment}-${var.documents_bucket_name}"


  lifecycle {
    prevent_destroy = false # set to true to prevent accidental deletion of the bucket
  }

  tags = {
    Environment = var.environment
    Name        = "${var.environment}-documents-files-${var.documents_bucket_name}"
  }
}

resource "aws_s3_bucket_versioning" "documents_files_versioning" {
  bucket = aws_s3_bucket.documents_files.id

  versioning_configuration {
    status = "Enabled"
  }
}

# encrypt the bucket using the default AWS S3 encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "documents_files_encryption" {
  bucket = aws_s3_bucket.documents_files.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# create a bucket policy to block public access to the documents files
resource "aws_s3_bucket_public_access_block" "documents_files_public_access" {
  bucket = aws_s3_bucket.documents_files.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


resource "aws_s3_bucket_lifecycle_configuration" "documents_files_lifecycle" {
  bucket = aws_s3_bucket.documents_files.id

  rule {
    id     = "archive-old-documents"
    status = "Enabled"
    filter {} # apply the rule to all objects in the bucket

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    # move the documents to standard_ia after 90 days
    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }

    # move the documents to glacier after 365 days
    transition {
      days          = 365
      storage_class = "GLACIER"
    }

    # Specifies configuration to expire non-current object versions
    noncurrent_version_expiration {
      noncurrent_days           = 30 # Expire non-current versions after 30 days
      newer_noncurrent_versions = 3  # Keep the 3 most recent non-current versions
    }
  }
}

resource "aws_s3_bucket_logging" "documents_files" {
  bucket        = aws_s3_bucket.documents_files.id
  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "documentsbucketlog/"
}
