api_addr = "http://vault-test.demo.net:8200"

cluster_name = "vault-test"

listener "tcp" {
  address = "0.0.0.0:8200"
  # just for demo
  tls_disable = true
}

storage "dynamodb" {
  ha_enabled = "true"
  region     = "us-west-2"
  table      = "vault-dynamodb-backend"
}
# Auto-unseal
seal "awskms" {
  region     = "us-west-2"
  # Set by environment variable VAULT_AWSKMS_SEAL_KEY_ID
  # kms_key_id = "example"
}
#storage "inmem" {}
