output "website_url" {
  description = "Point domain_name at cloudfront_domain_name (Route 53 alias / CNAME)"
  value       = "https://${var.domain_name}"
}

output "cloudfront_domain_name" {
  value = module.cloudfront.cloudfront_domain_name
}

output "cloudfront_distribution_id" {
  value = module.cloudfront.distribution_id
}

output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "asg_name" {
  value = module.ec2.asg_name
}

output "rds_address" {
  value = module.rds.db_address
}

output "db_secret_arn" {
  description = "Read with: aws secretsmanager get-secret-value --secret-id <arn>"
  value       = module.rds.db_secret_arn
}

output "vpc_id" {
  value = module.vpc.vpc_id
}
