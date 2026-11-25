# AWS managed policy IDs: fixed and the same in every account, so plan needs no AWS lookup
locals {
  caching_disabled_policy_id  = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad" # Managed-CachingDisabled
  caching_optimized_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6" # Managed-CachingOptimized
  # Managed-AllViewer: forwards Host, cookies, query strings. WordPress needs the real Host,
  # and CloudFront then checks the ALB certificate against domain_name, not the *.elb name.
  all_viewer_policy_id = "216adef6-5c7f-47e4-b989-5492eafa07d3"
}

resource "aws_cloudfront_distribution" "wordpress" {
  enabled         = true
  is_ipv6_enabled = true
  http_version    = "http2and3"
  price_class     = "PriceClass_200" # includes Asia
  aliases         = [var.domain_name]
  comment         = "WordPress school website"

  origin {
    domain_name = var.alb_dns_name
    origin_id   = "wordpress-alb"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only" # CloudFront -> ALB is encrypted too
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # Pages, wp-admin, login, forms: dynamic, never cached
  default_cache_behavior {
    target_origin_id       = "wordpress-alb"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    cache_policy_id          = local.caching_disabled_policy_id
    origin_request_policy_id = local.all_viewer_policy_id
  }

  # Images, CSS, JS (uploads, themes, plugins): cached at the edge
  ordered_cache_behavior {
    path_pattern           = "/wp-content/*"
    target_origin_id       = "wordpress-alb"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    cache_policy_id          = local.caching_optimized_policy_id
    origin_request_policy_id = local.all_viewer_policy_id
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # HTTPS for visitors
  viewer_certificate {
    acm_certificate_arn      = var.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = {
    Name = "wordpress-cloudfront"
  }
}
