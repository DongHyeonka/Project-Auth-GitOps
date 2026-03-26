#!/usr/bin/env bash

__provider_vault_token_cache="${__provider_vault_token_cache:-}"

provider_vault_addr() {
  printf '%s\n' "${VAULT_TRANSIT_ADDR:-http://127.0.0.1:18200}"
}

provider_vault_login_with_approle() {
  local role_id="$1"
  local secret_id="$2"

  if [[ -n "$__provider_vault_token_cache" ]]; then
    printf '%s\n' "$__provider_vault_token_cache"
    return 0
  fi

  __provider_vault_token_cache="$(
    VAULT_ADDR="$(provider_vault_addr)" \
      vault write -field=token auth/approle/login \
        role_id="$role_id" \
        secret_id="$secret_id"
  )"

  printf '%s\n' "$__provider_vault_token_cache"
}

provider_vault_token() {
  if [[ -n "${VAULT_TRANSIT_DEV_ROLE_ID:-}" && -n "${VAULT_TRANSIT_DEV_SECRET_ID:-}" ]]; then
    provider_vault_login_with_approle \
      "$VAULT_TRANSIT_DEV_ROLE_ID" \
      "$VAULT_TRANSIT_DEV_SECRET_ID"
    return 0
  fi

  if [[ -n "${VAULT_TRANSIT_DEV_BOOTSTRAP_TOKEN:-}" ]]; then
    printf '%s\n' "$VAULT_TRANSIT_DEV_BOOTSTRAP_TOKEN"
    return 0
  fi

  if [[ -n "${VAULT_TOKEN:-}" ]]; then
    printf '%s\n' "$VAULT_TOKEN"
    return 0
  fi

  echo "VAULT_TRANSIT_DEV_BOOTSTRAP_TOKEN or VAULT_TRANSIT_DEV_ROLE_ID/VAULT_TRANSIT_DEV_SECRET_ID or VAULT_TOKEN must be set." >&2
  return 1
}

provider_kv_get_json() {
  local path="$1"
  VAULT_ADDR="$(provider_vault_addr)" \
  VAULT_TOKEN="$(provider_vault_token)" \
    vault kv get -format=json "$path"
}

provider_read_workload_bootstrap_token() {
  provider_kv_get_json "kv/dev/workload/bootstrap" | jq -r '.data.data.VAULT_WORKLOAD_DEV_BOOTSTRAP_TOKEN // empty'
}

provider_read_workload_role_id() {
  provider_kv_get_json "kv/dev/workload/bootstrap" | jq -r '.data.data.VAULT_WORKLOAD_DEV_ROLE_ID // empty'
}

provider_read_workload_secret_id() {
  provider_kv_get_json "kv/dev/workload/bootstrap" | jq -r '.data.data.VAULT_WORKLOAD_DEV_SECRET_ID // empty'
}
