# hashicorp-vault-aws-ecs-example
This project uses Terraform to deploy an ECS cluster that hosts Hashicorp Vault containers in HA. The ECS cluster itself is spread across mulitple AZs. The Vault containers are spread across the ECS clusters.

NOTE: This was created quickly and purely as an example/educational purposes. Hopefully this helps someone.

# About pipeline.sh
This bash script will deploy and destroy the entire project. In order to deploy this project this script MUST be used. I created this script as my "pipeline" where I would normally use an actual pipeline.

## Requirements for pipeline
- Docker 19.03+
- AWS CLI 1.18+
    - AWS Profile must be setup and set in terraform
    - Sufficient permissions to deploy ECS, ECS, ECR, ELB.
- Terraform v0.12.23
- Vault 1.4.1


## Use
```shell
# Deploy entire project
./pipeline.sh deploy all
# Deploy only part of project. Ex. Made an update to ecs-service
./pipeline.sh apply ecs-service
# Destroy entire project. WARNING: This is set to auto-approve
./pipeline.sh destroy all
```

# Project Requirements
- SSL certificate and domain created for intra vault communication 
    - NOTE: This was tested with provisioning a domain from route53 and a SSL cert from AWS certificate manager
