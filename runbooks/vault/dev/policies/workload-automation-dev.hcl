path "kv/data/dev/platform/postgres/superuser" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "kv/metadata/dev/platform/postgres/superuser" {
  capabilities = ["read", "delete", "list"]
}

path "kv/data/dev/platform/postgres/auth-server" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "kv/metadata/dev/platform/postgres/auth-server" {
  capabilities = ["read", "delete", "list"]
}

path "kv/data/dev/platform/postgres/keycloak" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "kv/metadata/dev/platform/postgres/keycloak" {
  capabilities = ["read", "delete", "list"]
}

path "kv/data/dev/platform/keycloak/bootstrap-admin" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "kv/metadata/dev/platform/keycloak/bootstrap-admin" {
  capabilities = ["read", "delete", "list"]
}

path "kv/data/dev/platform/keycloak/client-auth-server" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "kv/metadata/dev/platform/keycloak/client-auth-server" {
  capabilities = ["read", "delete", "list"]
}

path "auth/kubernetes/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "auth/approle/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "sys/auth/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

path "sys/mounts/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

path "sys/policies/acl/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "database/config/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "database/roles/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "transit/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
