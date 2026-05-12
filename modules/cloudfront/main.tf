
# create a CloudFront distribution
resource "aws_cloudfront_distribution" "cdn" {
    enabled = true
    comment = "CloudFront distribution for static files-${var.environment}"
    default_root_object = "index.html"

# configure the origin to point to the S3 bucket for static files
    origin {
      domain_name = var.static_bucket_regional_domain_name
      origin_id = "S3staticOrigins"
      origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
    }

# configure the origin to point to the ALB for dynamic content
    origin {
      domain_name = var.alb_dns_name
      origin_id = "ALBorigins"

      custom_origin_config {
        http_port = 80
        https_port = 443
        origin_protocol_policy = "http-only"
        origin_ssl_protocols = [ "TLSv1.2" ]
      }
    }   

# configure the default cache behavior to forward requests to the static bucket for static content
    ordered_cache_behavior {
      path_pattern = "/static/*"
      target_origin_id = "S3staticOrigins"
      viewer_protocol_policy = "redirect-to-https"
      allowed_methods = [ "GET" , "HEAD" ]
      cached_methods = [ "GET" , "HEAD" ]

      forwarded_values {
        query_string = false
        cookies {
          forward = "none"
        }
      }
    }


# configure a cache behavior to forward requests to the ALB for dynamic content
 default_cache_behavior {
      target_origin_id = "ALBorigins"
      viewer_protocol_policy = "redirect-to-https"
      allowed_methods = [ "GET" , "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE" ]
      cached_methods = [ "GET" , "HEAD" ]

      forwarded_values {
        query_string = true
        cookies {
          forward = "all"
        }
      }
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
      name        = "cloudfront-distribution-${var.environment}"
      Environment = var.environment
    }
  
}