output "ecs_cluster_name" {
    value = aws_ecs_cluster.utility.name
}

output "ecs_ami_id" {
    value = data.aws_ami.ecs_image.id
}

output "autoscaling_group_name" {
    value = aws_autoscaling_group.utility.name
}

output "elb_arn" {
    value = aws_lb.this_lb.arn
}