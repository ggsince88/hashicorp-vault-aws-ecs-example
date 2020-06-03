variable "profile" {
    type = string
    default = "defaults"
}

variable "region" {
    type = string
    default = "us-west-2"
}

variable "vpc_id" {
    type = string
}

variable "environment" {
    type = string
    default = "develop"
}

variable "vpc_zone_identifier" {
    description = "List of subnets for ECS cluster"
    type = list
}

variable "key_name" {
    type = string
    default = "vault-example"
}
/*
variable "ecs_ami_id" {
    type = string
    default = "ami-04590e7389a6e577c"
}
*/
variable "ecs_instance_type" {
    type = string
    default = "m5ad.large"
}

variable "vault_dynamotable" {
    type = string
    default = "vault-example"
}

variable "ecs_capacity_provider_name" {
    type = string
    default = "utility-01-001"
}

variable "internal_elb" {
    type = bool
    description = "Set if Elastic Load Balancer should be internal or not."
    default = true
}

variable "elb_subnets" {
    type = list
}

variable "route53_zone_id" {
    type = string
    default = ""
    description = "If this is set then route53 will create a subdmain with var.vaultsubdomain"
}

variable "vault_subdomain" {
    type = string
    default = ""
    description = "Will create subdomain for vault in route53"
}

variable "cluster_size_min" {
    type = number
    default = 1
}

variable "cluster_size_max" {
    type = number
    default = 4
}

variable "cluster_desired_capacity" {
    type = number
    default = 3
}
