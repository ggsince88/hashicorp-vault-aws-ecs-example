#!/bin/bash
#
# My fake deploy pipeline!
#
set -e

export AWS_PROFILE="default"
ENVIRONMENT="develop"
PROJECT_HOME=$(pwd)
PROJECT_COMMIT_SHA=$(git rev-parse --short HEAD)
TIMESTAMP=$(date +"%Y%m%d")
export VAULT_ADDR=http://vault-test.demo.net:8200

function pipeline_apply {
    cd ${PROJECT_HOME}/${1}
    echo
    echo "=========== APPLYING ${1} ==========="
    terraform init -backend-config=${ENVIRONMENT}.tfbackend
    terraform apply -var-file=${ENVIRONMENT}.tfvars
    cd ${PROJECT_HOME}
}

function pipeline_apply_ecs-cluster {
    pipeline_apply terraform-ecs-cluster
}

function pipeline_apply_ecs-service {
    set_ecr_variables
    # pipeline_container_deploy
    cd ${PROJECT_HOME}/terraform-ecs-cluster
    export TF_VAR_elb_arn=$(terraform output elb_arn)
    pipeline_apply terraform-ecs-service
}

function pipeline_apply_ecr {
    pipeline_apply terraform-ecr
}

function pipeline_terraform-apply_all {
    pipeline_apply_ecr
    pipeline_apply_ecs-cluster
    pipeline_apply_ecs-service
}

function pipeline_destroy {
    cd ${PROJECT_HOME}/${1}
    echo
    echo "=========== DESTROYING ${1} ==========="
    terraform destroy -var-file=${ENVIRONMENT}.tfvars -auto-approve
    cd ${PROJECT_HOME}
}

function pipeline_destroy_ecs-cluster {
    cd ${PROJECT_HOME}/terraform-ecs-cluster
    echo
    echo "=========== DESTROY terraform-ecs-cluster ==========="
    export asg_name=$(terraform output autoscaling_group_name)
    # Terraform bug - must destroy ASG manually first. https://github.com/terraform-providers/terraform-provider-aws/issues/11409
    aws autoscaling delete-auto-scaling-group --auto-scaling-group-name ${asg_name} --force-delete
    terraform destroy -var-file=${ENVIRONMENT}.tfvars -auto-approve
    cd ${PROJECT_HOME}
}

function pipeline_destroy_ecs-service {
    set_ecr_variables
    pipeline_destroy terraform-ecs-service
}

function pipeline_destroy_ecr {
    pipeline_destroy terraform-ecr
}

function pipeline_destroy_all {
    pipeline_destroy_ecs-service
    pipeline_destroy_ecs-cluster
}

function get_commit_sha {
    git rev-parse --short HEAD
}

function set_ecr_variables {
    cd ${PROJECT_HOME}/terraform-ecr
    export container_name=$(terraform output service_name)
    export repo_url=$(terraform output repo_url)
    cd ${PROJECT_HOME}
    export commit_sha=$(get_commit_sha)
    export docker_tag="${TIMESTAMP}-${commit_sha}"
    export image_name="${container_name}:${TIMESTAMP}-${commit_sha}"
    export TF_VAR_image="${repo_url}:${docker_tag}"
}

function pipeline_container_build {
    set_ecr_variables
    cd ${PROJECT_HOME}
    if [ ! -f "Dockerfile" ]; then
        echo
        echo "ERROR: NO DOCKERFILE: No file 'Dockerfile' found."
        echo "    Unable to run this command without it, quitting."
        echo
        exit 1
    fi
    echo
    echo "=========== BUILDING CONTAINER ==========="
    docker build -t ${image_name} .
}

function pipeline_container_push {
    echo
    echo "=========== PUSHING CONTAINER TO ECR ==========="
    aws ecr get-login-password | docker login --username AWS --password-stdin ${repo_url}
    docker tag "${image_name}" "${repo_url}:${docker_tag}"
    docker push "${repo_url}:${docker_tag}"
}

function pipeline_container_deploy {
    pipeline_container_build
    pipeline_container_push
}

function pipeline_deploy_all {
    echo "=========== DEPLOYING ENTIRE PROJECT ==========="
    pipeline_apply_ecr
    pipeline_apply_ecs-cluster
    pipeline_container_deploy
    pipeline_apply_ecs-service
    sleep 10
    pipeline_vault_init
}

function pipeline_vault_init {
    echo
    echo "=========== VAULT INIT ==========="
    ssh bastion-host "vault operator init -address=${VAULT_ADDR} -recovery-shares=1 -recovery-threshold=1"
}

function main {
    command_type="${1}"
    command_target="${2}"

    "pipeline_${command_type}_${command_target}"
}

main $@
