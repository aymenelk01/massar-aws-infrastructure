###1. create a bucket for the static files
# create the bucket
resource "aws_s3_bucket" "static_files" {
  bucket = "${var.environment}-${var.static_bucket_name}"


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


