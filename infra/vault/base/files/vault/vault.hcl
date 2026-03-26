ui = true
disable_mlock = true

listener "tcp" {
  address = "0.0.0.0:8200"
  tls_disable = 1
}

seal "transit" {
  address         = "http://vault-transit.vault-transit.svc.cluster.local:8200"
  token           = "env://VAULT_TRANSIT_SEAL_TOKEN"
  disable_renewal = "false"
  key_name        = "workload-vault-dev-unseal"
  mount_path      = "transit/"
  tls_skip_verify = "true"
}

storage "raft" {
  path = "/vault/data"
  node_id = "vault-dev-0"
}
