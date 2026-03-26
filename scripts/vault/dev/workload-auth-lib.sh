#!/usr/bin/env bash

__workload_vault_token_cache="${__workload_vault_token_cache:-}"

workload_vault_login_with_approle() {
  local role_id="$1"
  local secret_id="$2"

  if [[ -n "$__workload_vault_token_cache" ]]; then
    printf '%s\n' "$__workload_vault_token_cache"
    return 0
  fi

  __workload_vault_token_cache="$(
    VAULT_ADDR="${VAULT_WORKLOAD_ADDR:-${VAULT_ADDR:-http://127.0.0.1:8200}}" \
      vault write -field=token auth/approle/login \
        role_id="$role_id" \
        secret_id="$secret_id"
  )"

  printf '%s\n' "$__workload_vault_token_cache"
}

workload_vault_token() {
  local role_id=""
  local secret_id=""
  local token=""

  if [[ -n "${VAULT_WORKLOAD_DEV_BOOTSTRAP_TOKEN:-}" ]]; then
    printf '%s\n' "$VAULT_WORKLOAD_DEV_BOOTSTRAP_TOKEN"
    return 0
  fi

  if [[ -n "${VAULT_WORKLOAD_DEV_ROLE_ID:-}" && -n "${VAULT_WORKLOAD_DEV_SECRET_ID:-}" ]]; then
    workload_vault_login_with_approle \
      "$VAULT_WORKLOAD_DEV_ROLE_ID" \
      "$VAULT_WORKLOAD_DEV_SECRET_ID"
    return 0
  fi

  role_id="$(provider_read_workload_role_id 2>/dev/null || true)"
  secret_id="$(provider_read_workload_secret_id 2>/dev/null || true)"
  if [[ -n "$role_id" && -n "$secret_id" ]]; then
    workload_vault_login_with_approle "$role_id" "$secret_id"
    return 0
  fi

  token="$(provider_read_workload_bootstrap_token 2>/dev/null || true)"
  if [[ -n "$token" ]]; then
    printf '%s\n' "$token"
    return 0
  fi

  if [[ -n "${VAULT_TOKEN:-}" ]]; then
    printf '%s\n' "$VAULT_TOKEN"
    return 0
  fi

  echo "VAULT_WORKLOAD_DEV_ROLE_ID/VAULT_WORKLOAD_DEV_SECRET_ID or VAULT_WORKLOAD_DEV_BOOTSTRAP_TOKEN or VAULT_TOKEN must be set." >&2
  return 1
}
