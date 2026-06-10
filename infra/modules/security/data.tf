data "aws_region" "current" {}

# fetch the AWS-managed prefix list for S3 to allow ECS tasks to access S3 without traversing the public internet, enhancing security and reducing latency by keeping the traffic within the AWS network
data "aws_ec2_managed_prefix_list" "s3" {
  name = "com.amazonaws.${data.aws_region.current.region}.s3"
}

# fetch the AWS-managed prefix list for CloudFront to allow only CloudFront to access the ALB on port 80, enhancing security by restricting access to the ALB to only CloudFront and preventing direct access from the internet
data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}