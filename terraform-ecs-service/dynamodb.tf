# Vault specific infra
# Using DynamoDB backend
resource "aws_dynamodb_table" "vault_dynamodb_table" {
    name = var.vault_dynamotable
    read_capacity  = 5
    write_capacity = 5
    hash_key = "Path"
    range_key = "Key"

    attribute {
        name = "Path"
        type = "S"
    }
    attribute {
        name = "Key"
        type = "S"
    }

    tags = {
        Name = "vault-dynamodb-table"
        terraform = "true"
        vault-example = "true"
    }
}