resource "aws_lb" "mylb" {
    name = "wpalb"
    internal = false
    load_balancer_type = "application"
    security_groups = [aws_security_group.lbsg.id]
    subnets = [aws_subnet.pubsub1.id, aws_subnet.pubsub2.id]
}

resource "aws_lb_target_group" "lbtg" {
    name = "wpalbtg"
    port = 80
    protocol = "HTTP"
    vpc_id = aws_vpc.myvpc.id
    health_check {
      path = "/"
      protocol = "HTTP"
      interval = 15
      timeout = 10
      healthy_threshold = 2
      unhealthy_threshold = 3
      matcher = "200-399"
    }
}

resource "aws_lb_listener" "lblist" {
    load_balancer_arn = aws_lb.mylb.arn
    port = 80
    protocol = "HTTP"

    default_action {
        type = "forward"
        target_group_arn = aws_lb_target_group.lbtg.arn
    }
}

locals {
  wp_services = ["service1", "service2"]
}

resource "aws_ecs_task_definition" "wp_task" {
    for_each = toset(local.wp_services)
    family = "wordpress-${each.key}"
    network_mode = "bridge"
    requires_compatibilities = ["EC2"]
    memory = "512"
    cpu = "256"

    container_definitions = jsonencode([
        {
            name = "wordpress-${each.key}"
            image = "wordpress:latest"
            cpu = 256
            memory = 512
            essential = true
            portMappings = [
                {
                    containerPort = 80
                    hostPort = 0
                }
            ]
            environment = [
                {name = "WORDPRESS_DB_NAME", value = "${each.key}_db"},
                {name = "WORDPRESS_DB_USER", value = aws_db_instance.mydb.username},
                {name = "WORDPRESS_DB_PASSWORD", value = aws_db_instance.mydb.password},
                {name = "WORDPRESS_DB_HOST", value = aws_db_instance.mydb.address}
            ]
            mountPoints = [
                {
                    sourceVolume = "wordpress-storage"
                    containerPath = "/var/www/html"
                }
            ]
        }
    ])

    volume {
        name = "wordpress-storage"
        efs_volume_configuration {
          file_system_id = aws_efs_file_system.myefs.id
          root_directory = "/${each.key}"
        }
        
    }
}

resource "aws_ecs_service" "wp_service" {
    for_each = toset(local.wp_services)
    name = "wordpress-service-${each.key}"
    cluster = aws_ecs_cluster.wp_cluster.id
    task_definition = aws_ecs_task_definition.wp_task[each.key].arn
    desired_count = 1

    load_balancer {
      target_group_arn = aws_lb_target_group.lbtg.arn
      container_name = "wordpress-${each.key}"
      container_port = 80
    }
}