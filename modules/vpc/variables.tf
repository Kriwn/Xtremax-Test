variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "azs" {
  type        = list(string)
  description = "Availability zones (written out, not looked up, so plan works without an AWS account)"
  default     = ["ap-southeast-1a", "ap-southeast-1b"]

  validation {
    condition     = length(var.azs) >= 2
    error_message = "ALB and RDS need subnets in at least 2 AZs."
  }
}
