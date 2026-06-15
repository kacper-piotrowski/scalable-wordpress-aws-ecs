data "aws_iam_role" "lab_role" {
  name = "LabRole"
}


resource "aws_lb" "mylb" {
    name = "wpalb"
    internal = false
    load_balancer_type = "application"
    security_groups = [aws_security_group.lbsg.id]
    subnets = [aws_subnet.pubsub1.id, aws_subnet.pubsub2.id]
}

resource "aws_lb_target_group" "lbtg" {
    for_each = local.wp_services
    name = "wptg-${each.key}"
    port = 80
    protocol = "HTTP"
    vpc_id = aws_vpc.myvpc.id
    deregistration_delay = 10
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
    for_each = local.wp_services
    load_balancer_arn = aws_lb.mylb.arn
    port = each.value
    protocol = "HTTP"

    default_action {
        type = "forward"
        target_group_arn = aws_lb_target_group.lbtg[each.key].arn
    }
}

locals {
  wp_services = {
    "service1" = 8081
    "service2" = 8082
  }
}

resource "aws_ecs_task_definition" "wp_task" {
    for_each = local.wp_services
    family = "wordpress-${each.key}"
    network_mode = "bridge"
    requires_compatibilities = ["EC2"]
    memory = "512"
    cpu = "256"
    execution_role_arn = data.aws_iam_role.lab_role.arn
    task_role_arn = data.aws_iam_role.lab_role.arn

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
          transit_encryption = "ENABLED"
          authorization_config {
            access_point_id = aws_efs_access_point.wp_ap[each.key].id
          }
        }
    }
}

resource "aws_ecs_service" "wp_service" {
    for_each = local.wp_services
    name = "wordpress-service-${each.key}"
    cluster = aws_ecs_cluster.wp_cluster.id
    task_definition = aws_ecs_task_definition.wp_task[each.key].arn
    desired_count = 2
    force_new_deployment = true
    depends_on = [ aws_lb_listener.lblist, aws_ecs_cluster_capacity_providers.wp_cluster_capacity_provider, aws_instance.bastion, 
    aws_efs_mount_target.efsmt1, aws_efs_mount_target.efsmt2 ]

    capacity_provider_strategy {
      capacity_provider = aws_ecs_capacity_provider.wp_capacity_provider.name
      weight = 1
      base = 1
    }

    load_balancer {
      target_group_arn = aws_lb_target_group.lbtg[each.key].arn
      container_name = "wordpress-${each.key}"
      container_port = 80
    }
}

resource "aws_appautoscaling_target" "ecs_target" {
    for_each = local.wp_services
    max_capacity = 3
    min_capacity = 1
    resource_id = "service/${aws_ecs_cluster.wp_cluster.name}/wordpress-service-${each.key}"
    scalable_dimension = "ecs:service:DesiredCount"
    service_namespace = "ecs"
    depends_on = [ aws_ecs_service.wp_service ]
}

resource "aws_appautoscaling_policy" "wp_scaling" {
    for_each = local.wp_services
    name = "wp-scaling-policy-${each.key}"
    resource_id = aws_appautoscaling_target.ecs_target[each.key].resource_id
    policy_type = "TargetTrackingScaling"
    scalable_dimension = "ecs:service:DesiredCount"
    service_namespace = "ecs"
    target_tracking_scaling_policy_configuration {
      target_value = 80.0
      predefined_metric_specification {
        predefined_metric_type = "ECSServiceAverageCPUUtilization"
      }
    }
}

resource "aws_efs_access_point" "wp_ap" {
    for_each = local.wp_services
    file_system_id = aws_efs_file_system.myefs.id
    
    posix_user {
        uid = 33
        gid = 33
    }
    
    root_directory {
        path = "/${each.key}"
        creation_info {
            owner_uid = 33
            owner_gid = 33
            permissions = "0777"
        }
    }
}