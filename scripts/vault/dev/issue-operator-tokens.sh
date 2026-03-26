#!/usr/bin/env bash

set -euo pipefail

VAULT_ADDR="${VAULT_ADDR:-http://127.0.0.1:8200}"
VAULT_TOKEN="${VAULT_TOKEN:-}"
TOKEN_TTL="${TOKEN_TTL:-1h}"

if [[ -z "$VAULT_TOKEN" ]]; then
  echo "VAULT_TOKEN must be set to a platform-admin-dev token." >&2
  exit 1
fi

for cmd in vault; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "$cmd is required" >&2
    exit 1
  fi
done

export VAULT_ADDR
export VAULT_TOKEN

postgres_token="$(
  vault token create -orphan -policy=postgres-operator-dev -ttl="$TOKEN_TTL" -field=token
)"

keycloak_token="$(
  vault token create -orphan -policy=keycloak-operator-dev -ttl="$TOKEN_TTL" -field=token
)"

echo ""
echo "postgres-operator-dev token:"
echo "$postgres_token"
echo ""
echo "keycloak-operator-dev token:"
echo "$keycloak_token"
echo ""
