ui = true
disable_mlock = true
api_addr = "http://vault-transit.vault-transit.svc.cluster.local:8200"
cluster_addr = "http://vault-transit.vault-transit.svc.cluster.local:8201"

listener "tcp" {
  address = "0.0.0.0:8200"
  cluster_address = "0.0.0.0:8201"
  tls_disable = 1
}

storage "raft" {
  path = "/vault/data"
  node_id = "vault-transit-dev-0"
}
