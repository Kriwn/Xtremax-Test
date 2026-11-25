variable "aws_region" {
  type        = string
  description = "Region for everything except the CloudFront certificate"
  default     = "ap-southeast-1"
}

# Network
variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR block"
  default     = "10.0.0.0/16"
}

variable "azs" {
  type        = list(string)
  description = "Availability zones (at least 2)"
  default     = ["ap-southeast-1a", "ap-southeast-1b"]
}

# Domain and certificates (assumed to exist; see docs)
variable "domain_name" {
  type        = string
  description = "Website domain; both certificates must cover it"
}

variable "alb_certificate_arn" {
  type        = string
  description = "ACM certificate in ap-southeast-1 for domain_name (ALB)"
}

variable "cloudfront_certificate_arn" {
  type        = string
  description = "ACM certificate in us-east-1 for domain_name (CloudFront)"
}

# Compute
variable "image_id" {
  type        = string
  description = "Amazon Linux 2023 AMI ID in aws_region"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t3.micro"
}

# Database
variable "db_name" {
  type        = string
  description = "WordPress database name"
  default     = "wordpress"
}

variable "db_username" {
  type        = string
  description = "RDS master username (the password is generated into Secrets Manager)"
  default     = "wpadmin"
}

variable "db_instance_class" {
  type        = string
  description = "RDS instance class"
  default     = "db.t3.micro"
}

variable "multi_az" {
  type        = bool
  description = "RDS standby in a second AZ; true for production"
  default     = false
}
