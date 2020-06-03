output "service_name" {
    value = aws_ecs_task_definition.task.family
}

output "ecs_vault_task_role" {
    value = aws_iam_role.ecs_vault_task_role.arn
}