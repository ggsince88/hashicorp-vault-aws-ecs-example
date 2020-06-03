terraform {
    required_version = ">= 0.12.20"
    backend "s3" {}
    required_providers {
        aws = "~> 2.59"
    }
}

provider "aws" {
    region = var.region
    profile = var.profile
}

data "aws_ecs_cluster" "cluster" {
    cluster_name = var.cluster
}

resource "aws_ecs_task_definition" "task" {
    depends_on = [ aws_iam_role_policy_attachment.ecs_vault_task_attachment, aws_kms_key.vault ]
    family = var.service_name
    task_role_arn = aws_iam_role.ecs_vault_task_role.arn
    container_definitions = <<EOF
[
    {
        "name": "${var.service_name}",
        "image": "${var.image}",
        "cpu": 10,
        "memory": 512,
        "essential": true,
        "environment": [
            {"name": "VAULT_AWSKMS_SEAL_KEY_ID", "value": "${aws_kms_key.vault.key_id}"}
        ],
        "portMappings": [
            {
                "containerPort": 8200,
                "hostPort": 8200,
                "protocol": "tcp"
            },
            {
                "containerPort": 8201,
                "hostPort": 8201,
                "protocol": "tcp"
            }
        ],
        "command": [
            "server"
        ],
        "linuxParameters": {
            "capabilities": {
                "add": ["IPC_LOCK"]
            }
        }
    }
]
    EOF
}

resource "aws_lb_target_group" "service_target_group" {
  name     = "${var.service_name}-lb-tg"
  port     = 8200
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  target_type = "instance"

  health_check {
      interval = 30
      path = "/v1/sys/health"
      # https://www.vaultproject.io/api/system/health.html
      matcher = "200,429,472,473"
  }
}

resource "aws_lb_listener" "vault_lb_listener_http" {
    load_balancer_arn = var.elb_arn
    port = "8200"
    protocol = "HTTP"

    default_action {
        type = "forward"
        target_group_arn = aws_lb_target_group.service_target_group.arn
    }

}
/*
resource "aws_lb_listener" "vault_lb_listener_https_8200" {
    load_balancer_arn = var.elb_arn
    port = "8200"
    protocol = "HTTPS"
    ssl_policy = "ELBSecurityPolicy-2016-08"
    certificate_arn = var.certificate_arn

    default_action {
        type = "forward"
        target_group_arn = aws_lb_target_group.service_target_group.arn
    }

}
*/
resource "aws_lb_listener" "vault_lb_listener_https" {
    load_balancer_arn = var.elb_arn
    port = "8201"
    protocol = "HTTPS"
    ssl_policy = "ELBSecurityPolicy-2016-08"
    certificate_arn = var.certificate_arn

    default_action {
        type = "forward"
        target_group_arn = aws_lb_target_group.service_target_group.arn
    }

}

resource "aws_ecs_service" "service" {
    name = var.service_name
    launch_type = "EC2"
    cluster = data.aws_ecs_cluster.cluster.id
    task_definition = aws_ecs_task_definition.task.arn
    iam_role = aws_iam_role.ecs_vault_service_role.arn
    desired_count = var.desired_count
    deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
    deployment_maximum_percent = var.deployment_maximum_percent

    scheduling_strategy = "REPLICA"

    ordered_placement_strategy {
        type = "spread"
        field = "attribute:ecs.availability-zone"
    }
    ordered_placement_strategy {
        type = "spread"
        field = "instanceId"
    }

    load_balancer {
        target_group_arn = aws_lb_target_group.service_target_group.arn
        container_name = var.service_name
        container_port = 8200
    }

    depends_on = [aws_iam_role.ecs_vault_task_role, aws_iam_role.ecs_vault_service_role]
}