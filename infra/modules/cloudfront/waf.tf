resource "aws_wafv2_web_acl" "waf" {
  provider    = aws.us_east_1 # WAF must be created in us-east-1 for CloudFront distributions
  name        = "massar-waf-${var.environment}"
  description = "WAF for Massar application - ${var.environment} environment"
  scope       = "CLOUDFRONT" # WAF scope must be CLOUDFRONT for CloudFront distributions

  default_action {
    allow {}
  }

  rule {
    name     = "login-rule-limit"
    priority = 1

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 10
        aggregate_key_type = "IP"
        scope_down_statement {
          byte_match_statement {
            search_string = "login"
            field_to_match {
              uri_path {}
            }
            text_transformation {
              priority = 0
              type     = "NONE"
            }
            positional_constraint = "CONTAINS"
          }
        }
      }
    }


    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "loginRuleLimit"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "blanket-rate-limit"
    priority = 2

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 500
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "blanketRateLimit"
      sampled_requests_enabled   = true
    }
  }

rule {
  name = "ip-reputation-rule"
  priority = 3

    override_action {
        none {}
    }

    statement {
        managed_rule_group_statement {
            name = "AWSManagedRulesAmazonIpReputationList"
            vendor_name = "AWS"
        }
    }

    visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "ipReputationRule"
    sampled_requests_enabled   = true
  }
}

rule {
  name = "common-rule-set"
  priority = 4

    override_action {
        none {}
    }

    statement {
        managed_rule_group_statement {
            name = "AWSManagedRulesCommonRuleSet"
            vendor_name = "AWS"
        }
    }

    visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "commonRuleSet"
    sampled_requests_enabled   = true
  }
}

rule {
  name = "SQLi-rule-set"
  priority = 5

    override_action {
        none {}
    }

    statement {
        managed_rule_group_statement {
            name = "AWSManagedRulesSQLiRuleSet"
            vendor_name = "AWS"
        }
    }

    visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "SQLiRuleSet"
    sampled_requests_enabled   = true
  }
}


  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "massarWAF"
    sampled_requests_enabled   = true
  }
}
