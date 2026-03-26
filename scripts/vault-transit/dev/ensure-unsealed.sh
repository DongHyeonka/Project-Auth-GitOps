#!/usr/bin/env bash

set -euo pipefail

VAULT_ADDR="${VAULT_ADDR:-http://127.0.0.1:18200}"

export VAULT_ADDR

if ! command -v vault >/dev/null 2>&1; then
  echo "vault CLI is required" >&2
  exit 1
fi

status_json="$(mktemp)"
trap 'rm -f "$status_json"' EXIT

if vault status -format=json >"$status_json" 2>/dev/null; then
  :
else
  if [[ ! -s "$status_json" ]]; then
    echo "Vault transit provider is unreachable at ${VAULT_ADDR}" >&2
    exit 1
  fi
fi

initialized="$(jq -r '.initialized' "$status_json")"
sealed="$(jq -r '.sealed' "$status_json")"

if [[ "$initialized" != "true" ]]; then
  echo "Transit provider Vault is not initialized." >&2
  exit 1
fi

if [[ "$sealed" == "true" ]]; then
  cat >&2 <<'EOF'
Transit provider Vault is sealed.
Manual unseal is required before the CI reconcile workflow can continue.
Run the provider Vault runbook from runbooks/vault-transit/dev/README.md and unseal the vault-transit instance first.
EOF
  exit 1
fi
