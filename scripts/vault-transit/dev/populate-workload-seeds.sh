#!/usr/bin/env bash

set -euo pipefail

if ! command -v vault >/dev/null 2>&1; then
  echo "vault CLI is required" >&2
  exit 1
fi

prompt_secret() {
  local var_name="$1"
  local label="$2"
  local value=""
  local confirm=""

  while true; do
    read -r -s -p "${label}: " value
    echo
    read -r -s -p "${label} (confirm): " confirm
    echo

    if [[ "$value" != "$confirm" ]]; then
      echo "Values did not match. Try again." >&2
      continue
    fi

    if [[ -z "$value" ]]; then
      echo "Value must not be empty." >&2
      continue
    fi

    printf -v "$var_name" '%s' "$value"
    break
  done
}

prompt_value() {
  local var_name="$1"
  local label="$2"
  local default_value="${3:-}"
  local value=""

  if [[ -n "$default_value" ]]; then
    read -r -p "${label} [${default_value}]: " value
    value="${value:-$default_value}"
  else
    read -r -p "${label}: " value
  fi

  if [[ -z "$value" ]]; then
    echo "Value must not be empty." >&2
    exit 1
  fi

  printf -v "$var_name" '%s' "$value"
}

echo "Populate provider Vault workload seeds"
echo "VAULT_ADDR=${VAULT_ADDR:-unset}"
echo "This script prompts securely so values are not exposed in shell history."
echo "The workload workflow AppRole bootstrap path is managed by Terraform."
echo

prompt_secret PLATFORM_POSTGRES_SUPERUSER_PASSWORD "Platform Postgres superuser password"
prompt_value AUTH_SERVER_DATASOURCE_USERNAME "Postgres auth-server username" "project_auth"
prompt_secret AUTH_SERVER_DATASOURCE_PASSWORD "Postgres auth-server password"
prompt_secret PLATFORM_KEYCLOAK_DB_PASSWORD "Postgres keycloak password"
prompt_secret PLATFORM_KEYCLOAK_BOOTSTRAP_ADMIN_PASSWORD "Platform Keycloak bootstrap admin password"
prompt_secret AUTH_SERVER_KEYCLOAK_CLIENT_SECRET "Keycloak auth-server client secret"

vault kv put kv/dev/workload/platform/postgres/superuser \
  POSTGRES_SUPERUSER_PASSWORD="$PLATFORM_POSTGRES_SUPERUSER_PASSWORD" >/dev/null

vault kv put kv/dev/workload/platform/postgres/auth-server \
  APP_DATASOURCE_USERNAME="$AUTH_SERVER_DATASOURCE_USERNAME" \
  APP_DATASOURCE_PASSWORD="$AUTH_SERVER_DATASOURCE_PASSWORD" \
  AUTH_DB_PASSWORD="$AUTH_SERVER_DATASOURCE_PASSWORD" >/dev/null

vault kv put kv/dev/workload/platform/postgres/keycloak \
  KEYCLOAK_DB_PASSWORD="$PLATFORM_KEYCLOAK_DB_PASSWORD" >/dev/null

vault kv put kv/dev/workload/platform/keycloak/bootstrap-admin \
  KC_BOOTSTRAP_ADMIN_PASSWORD="$PLATFORM_KEYCLOAK_BOOTSTRAP_ADMIN_PASSWORD" >/dev/null

vault kv put kv/dev/workload/platform/keycloak/client-auth-server \
  APP_SECURITY_OAUTH2_KEYCLOAK_CLIENT_SECRET="$AUTH_SERVER_KEYCLOAK_CLIENT_SECRET" \
  KEYCLOAK_CLIENT_SECRET="$AUTH_SERVER_KEYCLOAK_CLIENT_SECRET" >/dev/null

echo
echo "Provider Vault workload seed values updated."
