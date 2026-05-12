# create an origin access control for the CloudFront distribution to access the S3 buckets
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "oac_for_cloudfront"
  description                       = "Origin Access Control for CloudFront to access S3 buckets"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                = "sigv4"
}
