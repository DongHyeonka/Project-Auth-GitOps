path "kv/data/dev/platform/postgres/auth-server" {
  capabilities = ["read"]
}

path "kv/data/dev/platform/keycloak/client-auth-server" {
  capabilities = ["read"]
}

path "transit/keys/project-auth-jwt" {
  capabilities = ["read"]
}

path "transit/sign/project-auth-jwt" {
  capabilities = ["update"]
}
