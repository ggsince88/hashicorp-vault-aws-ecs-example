output "repo_url" {
    value = aws_ecr_repository.repository.repository_url
}

output "service_name" {
    value = aws_ecr_repository.repository.name
}