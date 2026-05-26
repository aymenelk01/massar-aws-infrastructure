### create bucket for the state files
#1. create the bucket
resource "aws_s3_bucket" "state_files" {
    bucket = "${var.environment}-${var.state_bucket_name}"

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

# create a dynamoDB table for the state lock
resource "aws_dynamodb_table" "state_lock" {
    name = "terraform-lock-${var.environment}"
    billing_mode = "PAY_PER_REQUEST"
    hash_key = "LockID"

    attribute {
        name = "LockID"
        type = "S"
    }

    tags = {
        Environment = var.environment
        Name        = "Terraform_Lock_Table-${var.environment}"
    }
}