output "distribution_id" {
  description = "Used to invalidate the cache"
  value       = aws_cloudfront_distribution.wordpress.id
}

output "cloudfront_domain_name" {
  description = "xxxx.cloudfront.net, the target of the Route 53 alias for domain_name"
  value       = aws_cloudfront_distribution.wordpress.domain_name
}

output "cloudfront_zone_id" {
  description = "Hosted zone ID for the Route 53 alias record"
  value       = aws_cloudfront_distribution.wordpress.hosted_zone_id
}
