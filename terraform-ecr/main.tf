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

resource "aws_ecr_repository" "repository" {
    name = var.service_name
    image_tag_mutability = "MUTABLE"
}