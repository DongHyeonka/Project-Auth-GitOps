ui = true
disable_mlock = true
api_addr = "http://vault.vault.svc.cluster.local:8200"
cluster_addr = "http://vault.vault.svc.cluster.local:8201"

listener "tcp" {
  address = "0.0.0.0:8200"
  cluster_address = "0.0.0.0:8201"
  tls_disable = 1
}

seal "transit" {
  address         = "http://vault-transit.vault-transit.svc.cluster.local:8200"
  disable_renewal = "false"
  key_name        = "workload-vault-dev-unseal"
  mount_path      = "transit/"
  tls_skip_verify = "true"
}

storage "raft" {
  path = "/vault/data"
  node_id = "vault-dev-0"
}
