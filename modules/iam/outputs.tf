output "instance_profile_name" {
  description = "For ec2 iam_instance_profile"
  value       = aws_iam_instance_profile.wordpress.name
}

output "role_name" {
  value = aws_iam_role.ec2_role.name
}
