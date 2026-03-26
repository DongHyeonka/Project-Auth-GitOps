#!/usr/bin/env bash

set -euo pipefail

VAULT_ADDR="${VAULT_ADDR:-http://127.0.0.1:8200}"

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
    echo "Vault is unreachable at ${VAULT_ADDR}" >&2
    exit 1
  fi
fi

initialized="$(jq -r '.initialized' "$status_json")"
sealed="$(jq -r '.sealed' "$status_json")"

if [[ "$initialized" != "true" ]]; then
  echo "Workload Vault is not initialized." >&2
  exit 1
fi

if [[ "$sealed" == "true" ]]; then
  echo "Workload Vault is still sealed. Check the transit unseal provider and vault-transit-seal secret." >&2
  exit 1
fi
