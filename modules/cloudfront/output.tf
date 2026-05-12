
output "cloudfront_distribution_id" {
  description = "The ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.cdn.id
}

output "cloudfront_domain_name" {
  description = "The domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.cdn.domain_name
  
}

output "cdn_arn" {
  description = "The ARN of the CloudFront distribution for the CDN"
  value       = aws_cloudfront_distribution.cdn.arn
}