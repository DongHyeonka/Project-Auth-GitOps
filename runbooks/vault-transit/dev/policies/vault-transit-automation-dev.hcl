path "transit/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "kv/data/dev/workload/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "kv/metadata/dev/workload/*" {
  capabilities = ["read", "delete", "list"]
}

path "sys/internal/ui/mounts/*" {
  capabilities = ["read"]
}

path "sys/mounts/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

path "sys/policies/acl/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "auth/token/create-orphan" {
  capabilities = ["update"]
}

path "auth/token/revoke" {
  capabilities = ["update"]
}

path "auth/token/lookup" {
  capabilities = ["update"]
}
