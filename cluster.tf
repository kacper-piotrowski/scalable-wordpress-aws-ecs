data "aws_ssm_parameter" "ecs_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2023/recommended/image_id"
}

resource "aws_ecs_cluster" "wp_cluster" {
    name = "wordpress-cluster"
}

resource "aws_launch_template" "ecs_template" {
    name_prefix            = "ecs-template"
    image_id               = data.aws_ssm_parameter.ecs_ami.value
    instance_type          = var.chosentype == "TEST" ? "t3.micro" : (var.chosentype == "DEVELOPER" ? "t3.small" : "t3.medium")
    vpc_security_group_ids = [aws_security_group.wpsg.id]

    iam_instance_profile {
        name = var.iam_instance_profile_name
    }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo ECS_CLUSTER=${aws_ecs_cluster.wp_cluster.name} >> /etc/ecs/ecs.config
  EOF
  )
}

resource "aws_autoscaling_group" "wpasg" {
    name = "wordpress-asg"
    vpc_zone_identifier = [aws_subnet.privsub1.id, aws_subnet.privsub2.id]
    min_size = 2
    max_size = var.chosentype == "PRODUCTION" ? 6 : 3

    launch_template {
      id = aws_launch_template.ecs_template.id
      version = "$Latest"
    }

    tag {
      key = "AmazonECSManaged"
      value = true
      propagate_at_launch = true
    }
}

resource "aws_ecs_capacity_provider" "wp_capacity_provider" {
  name = "wordpress-capacity-provider-newer"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.wpasg.arn
    managed_termination_protection = "DISABLED"
    managed_scaling {
      maximum_scaling_step_size = 2
      minimum_scaling_step_size = 1
      status = "ENABLED"
      target_capacity = 80
    }
  }
  lifecycle {
    create_before_destroy = false
  }
}

resource "aws_ecs_cluster_capacity_providers" "wp_cluster_capacity_provider" {
  cluster_name = aws_ecs_cluster.wp_cluster.name
  capacity_providers = [aws_ecs_capacity_provider.wp_capacity_provider.name]
  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.wp_capacity_provider.name
    weight = 1
    base = 1
  }
  
}