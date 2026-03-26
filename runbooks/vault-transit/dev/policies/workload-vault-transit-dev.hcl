path "transit/encrypt/workload-vault-dev-unseal" {
  capabilities = ["update"]
}

path "transit/decrypt/workload-vault-dev-unseal" {
  capabilities = ["update"]
}

path "transit/rewrap/workload-vault-dev-unseal" {
  capabilities = ["update"]
}

path "transit/keys/workload-vault-dev-unseal" {
  capabilities = ["read"]
}
