###1. create a bucket for the documents files
# create the bucket
resource "aws_s3_bucket" "documents_files" {
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
        id = "archive-old-documents"
        status = "Enabled"
    filter {} # apply the rule to all objects in the bucket

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
    }
}
