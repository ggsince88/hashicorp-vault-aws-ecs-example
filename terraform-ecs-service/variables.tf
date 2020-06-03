variable "profile" {
    type = string
    default = "default"
}

variable "region" {
    type = string
    default = "us-west-2"
}

variable "vpc_id" {
    type = string
}

variable "cluster" {
    type = string
    default = "us-west-2-ecs-it-develop-utility-01"
}

variable "desired_count" {
    type = number
    default = 1
}

variable "deployment_minimum_healthy_percent" {
    type = number
    default = 0
}

variable "deployment_maximum_percent" {
    type = number
    default = 100
}

variable "service_name" {
    type = string
    default = "vault-test"
}

variable "image" {
    type = string
}

variable "vault_dynamotable" {
    type = string
    default = "vault-dynamodb-backend"
}

variable "elb_arn" {
    type = string
    description = "ELB ARN. This get sets by the pipeline by default"
    default = ""
}

variable "certificate_arn" {
    type = string
}
