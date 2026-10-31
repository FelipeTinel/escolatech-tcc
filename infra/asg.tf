# AMI Amazon Linux 2023 ARM64 (Graviton), resolvida pelo SSM Parameter Store.
# Obs.: quando a AWS publica uma AMI nova, o próximo plan gera nova versão do
# Launch Template e um instance refresh. Para fixar, troque por um ID de AMI.
data "aws_ssm_parameter" "al2023_arm64" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-arm64"
}

resource "aws_launch_template" "app" {
  name_prefix   = "${local.name}-lt-"
  image_id      = data.aws_ssm_parameter.al2023_arm64.value
  instance_type = var.instance_type

  iam_instance_profile {
    arn = aws_iam_instance_profile.app.arn
  }

  vpc_security_group_ids = [aws_security_group.app.id]

  # Sem associate_public_ip_address: instâncias ficam apenas em subnets privadas
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2 obrigatório
    http_put_response_hop_limit = 2          # permite acesso a partir do container
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = 20
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh.tpl", {
    region        = var.aws_region
    ecr_registry  = split("/", aws_ecr_repository.app.repository_url)[0]
    ecr_repo_url  = aws_ecr_repository.app.repository_url
    image_tag     = var.image_tag
    app_port      = var.app_port
    db_host       = aws_db_instance.main.address
    db_port       = aws_db_instance.main.port
    db_name       = var.db_name
    db_username   = var.db_username
    db_secret_arn = aws_db_instance.main.master_user_secret[0].secret_arn
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${local.name}-app"
      Project     = var.project_name
      Environment = var.environment
    }
  }

  tag_specifications {
    resource_type = "volume"
    tags = {
      Name        = "${local.name}-app"
      Project     = var.project_name
      Environment = var.environment
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "app" {
  name                = "${local.name}-asg"
  min_size            = var.asg_min_size
  max_size            = var.asg_max_size
  desired_capacity    = var.asg_desired_capacity
  vpc_zone_identifier = aws_subnet.private[*].id # 1 subnet privada por AZ

  target_group_arns         = [aws_lb_target_group.app.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300 # tempo para boot + docker pull
  default_instance_warmup   = 120

  launch_template {
    id      = aws_launch_template.app.id
    version = aws_launch_template.app.latest_version
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  tag {
    key                 = "Name"
    value               = "${local.name}-app"
    propagate_at_launch = true
  }

  # A capacidade desejada é gerida pelo Target Tracking e pelas scheduled actions
  lifecycle {
    ignore_changes = [desired_capacity]
  }
}

############################
# Target Tracking (CPU média ~60%)
############################
resource "aws_autoscaling_policy" "cpu" {
  name                   = "${local.name}-cpu-target-tracking"
  autoscaling_group_name = aws_autoscaling_group.app.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = var.cpu_target
  }
}

############################
# Elasticidade por horário
############################
resource "aws_autoscaling_schedule" "night_scale_down" {
  count = var.enable_scheduled_scaling ? 1 : 0

  scheduled_action_name  = "${local.name}-night-scale-down"
  autoscaling_group_name = aws_autoscaling_group.app.name
  recurrence             = var.scale_down_cron
  time_zone              = var.schedule_timezone
  min_size               = var.asg_min_size
  max_size               = var.night_max_size
  desired_capacity       = var.asg_min_size
}

resource "aws_autoscaling_schedule" "morning_scale_up" {
  count = var.enable_scheduled_scaling ? 1 : 0

  scheduled_action_name  = "${local.name}-morning-scale-up"
  autoscaling_group_name = aws_autoscaling_group.app.name
  recurrence             = var.scale_up_cron
  time_zone              = var.schedule_timezone
  min_size               = var.asg_min_size
  max_size               = var.asg_max_size
  desired_capacity       = var.asg_desired_capacity
}
