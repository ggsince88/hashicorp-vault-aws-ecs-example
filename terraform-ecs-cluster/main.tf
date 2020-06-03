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

locals {
    cluster_name = "${var.region}-ecs-${var.environment}-utility-01"
}

data "aws_ami" "ecs_image" {
    most_recent = true

    filter {
        name = "name"
        values = ["amzn-ami-*-amazon-ecs-optimized"]
    }

    filter {
        name = "virtualization-type"
        values = ["hvm"]
    }

    owners = ["amazon"]
}

resource "aws_autoscaling_group" "utility" {
    name = "${var.region}-autoscaling-${var.environment}-utility-01"
    launch_configuration = aws_launch_configuration.utility.name
    min_size = var.cluster_size_min
    max_size = var.cluster_size_max
    desired_capacity = var.cluster_desired_capacity
    vpc_zone_identifier = var.vpc_zone_identifier

    lifecycle {
        create_before_destroy = true
        # ignore external tags from AWS for Key AmazonECSManaged and propagate_at_launch
        ignore_changes = [ tag ]
    }
}

resource "aws_launch_configuration" "utility" {
    name = "${var.region}-launch-configuration-${var.environment}-utility-01"
    image_id = data.aws_ami.ecs_image.id
    instance_type = var.ecs_instance_type
    iam_instance_profile = aws_iam_instance_profile.utility.name
    security_groups = ["${aws_security_group.ecs_security_group.id}"]
    key_name = var.key_name

    lifecycle {
        create_before_destroy = true
    }

    user_data = <<EOF
#!/bin/bash
amazon-linux-extras disable docker
amazon-linux-extras install -y ecs
systemctl enable --no-block ecs
echo "ECS_CLUSTER=${local.cluster_name}" > /etc/ecs/ecs.config
echo "ECS_CHECKPOINT=false" >> /etc/ecs/ecs.config
systemctl start --no-block ecs
    EOF
}

resource "aws_ecs_capacity_provider" "utility" {
    # Need to change name anytime you destroy and deploy due to AWS bug. 
    # AWS doesn't allow you to delete capacity providers
    name = var.ecs_capacity_provider_name

    auto_scaling_group_provider {
        auto_scaling_group_arn = aws_autoscaling_group.utility.arn
        managed_termination_protection = "DISABLED"

        managed_scaling {
            maximum_scaling_step_size = var.cluster_size_max
            minimum_scaling_step_size = var.cluster_size_min
            status = "ENABLED"
            target_capacity = var.cluster_desired_capacity
        }
    }
}

resource "aws_ecs_cluster" "utility" {
    name = local.cluster_name
    capacity_providers = [ aws_ecs_capacity_provider.utility.name ]
}
