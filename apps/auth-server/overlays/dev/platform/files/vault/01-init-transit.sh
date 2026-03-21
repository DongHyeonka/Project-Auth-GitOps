#!/bin/sh

set -eu

until vault status -address="${VAULT_ADDR}" >/dev/null 2>&1; do
  sleep 2
done

vault secrets enable transit || true
vault write "transit/keys/${VAULT_TRANSIT_KEY_NAME}" type="rsa-2048" || true
vault read "transit/keys/${VAULT_TRANSIT_KEY_NAME}"
