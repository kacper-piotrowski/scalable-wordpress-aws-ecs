data "aws_ami" "ecs_ami" {
    most_recent = true
    owners = ["amazon"]
    filter {
      name = "name"
      values = ["al2023-ami-ecs-hvm-*-x86_64-ebs"]
    }
}

resource "aws_ecs_cluster" "wp_cluster" {
    name = "wordpress-cluster"
}

resource "aws_launch_template" "ecs_template" {
    name_prefix = "ecs-template"
    image_id = data.aws_ami.ecs_ami.id
    instance_type = var.chosentype == "TEST" ? "t3.micro" : (var.chosentype == "DEVELOPER" ? "t3.small" : "t3.medium")
    vpc_security_group_ids = [aws_security_group.wpsg.id]
    user_data = base64encode(<<-EOF
    #!/bin/bash
    echo "ECS_CLUSTER=${aws_ecs_cluster.wp_cluster.name}" >> /etc/ecs/ecs.config
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

  
}