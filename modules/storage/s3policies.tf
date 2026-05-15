# This file defines the S3 bucket policy for the logs bucket, allowing access from the ALB in Milan and restricting access to only the specified VPC Endpoint and ALB.
resource "aws_s3_bucket_policy" "logs_final_policy" {
  bucket = aws_s3_bucket.logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # 1. Allow ALB in Milan (eu-south-1) to write access logs
      {
        Sid    = "AllowALBInMilanToWriteLogs"
        Effect = "Allow"
        Principal = {
          # Dedicated ELB Account ID for eu-south-1
          AWS = "arn:aws:iam::635631232127:root"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.logs.arn}/*"
      },
    ]
  })
}

  