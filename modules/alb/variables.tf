variable "vpc_id" {
  type        = string
  description = "The ID of the VPC"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR; the ALB may send HTTP 80 only inside it"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Public subnet IDs for the ALB (one per AZ)"

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "An ALB needs subnets in at least 2 AZs."
  }
}

variable "certificate_arn" {
  type        = string
  description = "ACM certificate (ap-southeast-1) for the same domain as CloudFront"
}

variable "cloudfront_prefix_list_id" {
  type        = string
  description = "AWS managed prefix list com.amazonaws.global.cloudfront.origin-facing (ap-southeast-1)"
  default     = "pl-31a34658"
}

variable "enable_deletion_protection" {
  type        = bool
  description = "Block deleting the ALB; true for production"
  default     = false
}
