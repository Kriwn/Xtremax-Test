data "aws_region" "current" {}

resource "aws_launch_template" "wordpress" {
  name_prefix   = "wordpress-"
  image_id      = var.image_id
  instance_type = var.instance_type

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    region        = data.aws_region.current.name
    db_name       = var.db_name
    db_host       = var.db_host
    db_secret_arn = var.db_secret_arn
  }))

  iam_instance_profile {
    name = var.iam_instance_profile
  }

  network_interfaces {
    device_index                = 0
    associate_public_ip_address = false
    security_groups             = [aws_security_group.wordpress_ec2_sg.id]
  }

  metadata_options {
    http_tokens = "required"
  }

  # Encrypted root disk
  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = 20
      volume_type = "gp3"
      encrypted   = true
    }
  }

  monitoring {
    enabled = true
  }
}


resource "aws_security_group" "wordpress_ec2_sg" {
  name        = "wordpress-ec2-sg"
  description = "Allow HTTP from ALB"
  vpc_id      = var.vpc_id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [var.sg_alb_id]
  }

  egress {
    description = "HTTPS out: packages, WordPress, Secrets Manager"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "HTTP out: package mirrors"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "MySQL to RDS inside the VPC"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
}


resource "aws_autoscaling_group" "wordpress_asg" {
  name = "wordpress-asg"

  min_size = 1
  max_size = 4

  vpc_zone_identifier = var.subnet_ids
  target_group_arns   = [var.target_group_arn]

  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.wordpress.id
    version = aws_launch_template.wordpress.latest_version
  }

  tag {
    key                 = "Name"
    value               = "wordpress-instance"
    propagate_at_launch = true
  }
}


# 1. Scale Up Policy
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "scale-up"
  autoscaling_group_name = aws_autoscaling_group.wordpress_asg.name

  policy_type        = "SimpleScaling"
  adjustment_type    = "ChangeInCapacity"
  scaling_adjustment = 1
  cooldown           = 300
}

# 2. Scale Down Policy
resource "aws_autoscaling_policy" "scale_down" {
  name                   = "scale-down"
  autoscaling_group_name = aws_autoscaling_group.wordpress_asg.name

  policy_type        = "SimpleScaling"
  adjustment_type    = "ChangeInCapacity"
  scaling_adjustment = -1
  cooldown           = 300
}


# 3. Scale Up Alarm: CPU > 80% for 30 minutes (30 x 60 s)
resource "aws_cloudwatch_metric_alarm" "scale_up_alarm" {
  alarm_name          = "scale-up-alarm"
  comparison_operator = "GreaterThanThreshold"

  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  statistic           = "Average"
  threshold           = 80
  period              = 60
  evaluation_periods  = 30
  datapoints_to_alarm = 30

  alarm_description = "Scale up if CPU > 80%"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.wordpress_asg.name
  }

  alarm_actions = [aws_autoscaling_policy.scale_up.arn]
}

# 4. Scale Down Alarm: CPU < 40% for 30 minutes (30 x 60 s)
resource "aws_cloudwatch_metric_alarm" "scale_down_alarm" {
  alarm_name          = "scale-down-alarm"
  comparison_operator = "LessThanThreshold"

  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  statistic           = "Average"
  threshold           = 40
  period              = 60
  evaluation_periods  = 30
  datapoints_to_alarm = 30

  alarm_description = "Scale down if CPU < 40%"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.wordpress_asg.name
  }

  alarm_actions = [aws_autoscaling_policy.scale_down.arn]
}
