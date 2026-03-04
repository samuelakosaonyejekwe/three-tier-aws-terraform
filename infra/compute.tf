data "aws_ami" "ubuntu_2204" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# WEB user-data: replace INTERNAL_ALB_DNS with internal ALB DNS
locals {
  web_user_data = base64encode(
    replace(
      file("${path.module}/../user-data/web.sh"),
      "INTERNAL_ALB_DNS",
      aws_lb.internal.dns_name
    )
  )

  # APP user-data:
  # Add DB env vars into /etc/apache2/envvars so Apache/PHP can read them.
  # (Note: This includes db password in user-data; acceptable for labs, not best practice for production.)
  app_user_data = base64encode(join("\n", [
    "#!/bin/bash",
    "set -euxo pipefail",
    "echo \"export DB_HOST='${aws_rds_cluster.aurora.endpoint}'\" >> /etc/apache2/envvars",
    "echo \"export DB_USER='${var.db_master_username}'\" >> /etc/apache2/envvars",
    "echo \"export DB_PASS='${var.db_master_password}'\" >> /etc/apache2/envvars",
    "echo \"export DB_NAME='${var.db_name}'\" >> /etc/apache2/envvars",
    "bash -c \"$(cat <<'EOS'\n${file("${path.module}/../user-data/app.sh")}\nEOS\n)\"",
    "systemctl restart apache2"
  ]))
}

resource "aws_launch_template" "web_lt" {
  name_prefix   = "${local.name}-web-"
  image_id      = data.aws_ami.ubuntu_2204.id
  instance_type = var.web_instance_type

  vpc_security_group_ids = [aws_security_group.web_sg.id]
  user_data              = local.web_user_data

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_ssm_profile.name
  }

  metadata_options {
    http_tokens = "required"
  }

  tag_specifications {
    resource_type = "instance"
    tags          = merge(local.common_tags, { Name = "${local.name}-web" })
  }
}

resource "aws_autoscaling_group" "web_asg" {
  name                = "${local.name}-web-asg"
  desired_capacity    = var.web_desired_capacity
  min_size            = 2
  max_size            = 2
  vpc_zone_identifier = [aws_subnet.web_private[0].id, aws_subnet.web_private[1].id]

  target_group_arns = [aws_lb_target_group.web_tg.arn]

  launch_template {
    id      = aws_launch_template.web_lt.id
    version = "$Latest"
  }

  health_check_type         = "ELB"
  health_check_grace_period = 60

  tag {
    key                 = "Name"
    value               = "${local.name}-web"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_launch_template" "app_lt" {
  name_prefix   = "${local.name}-app-"
  image_id      = data.aws_ami.ubuntu_2204.id
  instance_type = var.app_instance_type

  vpc_security_group_ids = [aws_security_group.app_sg.id]
  user_data              = local.app_user_data

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_ssm_profile.name
  }

  metadata_options {
    http_tokens = "required"
  }

  tag_specifications {
    resource_type = "instance"
    tags          = merge(local.common_tags, { Name = "${local.name}-app" })
  }
}

resource "aws_autoscaling_group" "app_asg" {
  name                = "${local.name}-app-asg"
  desired_capacity    = var.app_desired_capacity
  min_size            = 2
  max_size            = 2
  vpc_zone_identifier = [aws_subnet.app_private[0].id, aws_subnet.app_private[1].id]

  target_group_arns = [aws_lb_target_group.app_tg.arn]

  launch_template {
    id      = aws_launch_template.app_lt.id
    version = "$Latest"
  }

  health_check_type         = "ELB"
  health_check_grace_period = 60

  tag {
    key                 = "Name"
    value               = "${local.name}-app"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}
