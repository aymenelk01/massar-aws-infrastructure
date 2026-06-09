

# create a CloudFront distribution
resource "aws_cloudfront_distribution" "cdn" {
  # checkov:skip=CKV2_AWS_47: Already attached to the WAF 
  # checkov:skip=CKV2_AWS_32: Already attached to default cache behavior and ordered cache behavior, which are both configured to redirect HTTP to HTTPS, so this is effectively enforced for all requests
  # checkov:skip=CKV_AWS_86: Passing via modern Standard Logging (v2) streaming directly to CloudWatch Logs instead of legacy S3 blocks
  # checkov:skip=CKV2_AWS_42: Portfolio project exception; using the default CloudFront URL to minimize domain registration costs
  # checkov:skip=CKV_AWS_174: Using default CloudFront certificate, no custom domain yet
  # checkov:skip=CKV_AWS_310: This is a portfolio project; multi-region redundancy is disabled to optimize costs
  # checkov:skip=CKV_AWS_374: CloudFront geo restriction — already documented: VPN bypass renders it ineffective
  # checkov:skip=CKV_AWS_305: No default root object — default origin is ALB, not S3. Root redirect handled by CloudFront Function rewriting / to /static/index.html
  enabled    = true
  web_acl_id = aws_wafv2_web_acl.waf.arn
  comment    = "CloudFront distribution for static files-${var.environment}"
  default_root_object = "index.html" 



  # configure the origin to point to the S3 bucket for static files
  origin {
    domain_name              = var.static_bucket_regional_domain_name
    origin_id                = "S3staticOrigins"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
    origin_path              = "/static" # this will ensure that requests to the root domain (e.g., /) will be forwarded to the /static path in the S3 bucket, allowing CloudFront to serve the index.html file for the root domain requests.
  }

  # configure the origin to point to the ALB for dynamic content
  origin {
    domain_name = var.alb_dns_name
    origin_id   = "ALBorigins"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # configure the default cache behavior to forward requests to the static bucket for static content
  default_cache_behavior {
    target_origin_id       = "S3staticOrigins"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]

    response_headers_policy_id = data.aws_cloudfront_response_headers_policy.security_headers.id
    cache_policy_id            = data.aws_cloudfront_cache_policy.optimized.id
  }


  # configure a cache behavior to forward requests to the ALB for dynamic content
  ordered_cache_behavior {
    path_pattern = "/api/*" # this will forward all requests that start with /api/ to the ALB, allowing it to handle the dynamic content requests. You can adjust this path pattern based on your application's routing structure and requirements.
    target_origin_id       = "ALBorigins"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD"]

    response_headers_policy_id = data.aws_cloudfront_response_headers_policy.security_headers.id
    origin_request_policy_id   = data.aws_cloudfront_origin_request_policy.all_viewer.id
    cache_policy_id            = data.aws_cloudfront_cache_policy.disabled.id

  }

  # configure the restrictions for the distribution (e.g., geo-restrictions)
  # you can restrict access to the distribution based on the geographic location of the viewer. For example, you can allow or block access from specific countries or regions. In this case, we will not apply any geo-restrictions and allow access from all locations.
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # configure the viewer certificate for HTTPS support
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name        = "cloudfront-distribution-${var.environment}"
    Environment = var.environment
  }

}


