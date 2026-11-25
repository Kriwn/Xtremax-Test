variable "alb_dns_name" {
  type        = string
  description = "DNS name of the ALB (origin)"
}

variable "domain_name" {
  type        = string
  description = "Website domain, e.g. school.example.com. The ALB certificate must cover this name too"
}

variable "certificate_arn" {
  type        = string
  description = "ACM certificate ARN for domain_name. CloudFront only accepts certificates from us-east-1"

  validation {
    condition     = can(regex("^arn:aws:acm:us-east-1:", var.certificate_arn))
    error_message = "The CloudFront certificate must be in us-east-1."
  }
}
