output "alb_sg_id" {
  description = "For ec2 sg_alb_id (only the ALB may reach EC2 on port 80)"
  value       = aws_security_group.alb_sg.id
}

output "target_group_arn" {
  description = "For ec2 target_group_arn (the ASG registers instances here)"
  value       = aws_lb_target_group.wordpress_target_group.arn
}

output "alb_dns_name" {
  description = "For cloudfront alb_dns_name (origin)"
  value       = aws_lb.wordpress_alb.dns_name
}
