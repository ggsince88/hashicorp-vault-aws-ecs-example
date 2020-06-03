
data "aws_iam_policy_document" "ecs_vault_task_document" {
    # depends_on = [ aws_dynamodb_table.vault_dynamodb_table ]
    statement {
        actions = [
            "dynamodb:DescribeLimits",
            "dynamodb:DescribeTimeToLive",
            "dynamodb:ListTagsOfResource",
            "dynamodb:DescribeReservedCapacityOfferings",
            "dynamodb:DescribeReservedCapacity",
            "dynamodb:ListTables",
            "dynamodb:BatchGetItem",
            "dynamodb:BatchWriteItem",
            "dynamodb:CreateTable",
            "dynamodb:DeleteItem",
            "dynamodb:GetItem",
            "dynamodb:GetRecords",
            "dynamodb:PutItem",
            "dynamodb:Query",
            "dynamodb:UpdateItem",
            "dynamodb:Scan",
            "dynamodb:DescribeTable"
        ]
        resources = ["${aws_dynamodb_table.vault_dynamodb_table.arn}"]
    }
}

data "aws_iam_policy_document" "vault_kms_unseal" {
  statement {
    sid       = "VaultKMSUnseal"
    effect    = "Allow"
    resources = ["${aws_kms_key.vault.arn}"]

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:DescribeKey",
    ]
  }
}

resource "aws_iam_policy" "ecs_kms_task_policy" {
    name = "policy"
    path = "/"
    policy = data.aws_iam_policy_document.vault_kms_unseal.json
}

resource "aws_iam_policy" "ecs_vault_task_policy" {
    name = "ecs_vault_task_policy"
    path = "/"
    policy = data.aws_iam_policy_document.ecs_vault_task_document.json
}

resource "aws_iam_role" "ecs_vault_task_role" {
    name = "ecs-vault-task"
    path = "/"
    assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
                "Service": ["ecs-tasks.amazonaws.com", "ec2.amazonaws.com"]
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
    EOF
}

resource "aws_iam_role_policy_attachment" "ecs_kms_task_attachment" {
    role = aws_iam_role.ecs_vault_task_role.name
    policy_arn = aws_iam_policy.ecs_kms_task_policy.arn
}

resource "aws_iam_role_policy_attachment" "ecs_vault_task_attachment" {
    role = aws_iam_role.ecs_vault_task_role.name
    policy_arn = aws_iam_policy.ecs_vault_task_policy.arn
}

# Needed to communicate with ELB
resource "aws_iam_role" "ecs_vault_service_role" {
    name = "ecs-vault-service"
    path = "/"
    assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
                "Service": "ecs.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
    EOF
}

resource "aws_iam_role_policy_attachment" "ecs_vault_service_attachment" {
    role = aws_iam_role.ecs_vault_service_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}
