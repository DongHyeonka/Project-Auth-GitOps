#!/usr/bin/env sh

set -eu

vault kv put kv/dev/workload/platform/postgres/superuser \
  POSTGRES_SUPERUSER_PASSWORD=change-me

vault kv put kv/dev/workload/platform/postgres/auth-server \
  APP_DATASOURCE_USERNAME=project_auth \
  APP_DATASOURCE_PASSWORD=change-me \
  AUTH_DB_PASSWORD=change-me

vault kv put kv/dev/workload/platform/postgres/keycloak \
  KEYCLOAK_DB_PASSWORD=change-me

vault kv put kv/dev/workload/platform/keycloak/bootstrap-admin \
  KC_BOOTSTRAP_ADMIN_PASSWORD=change-me

vault kv put kv/dev/workload/platform/keycloak/client-auth-server \
  APP_SECURITY_OAUTH2_KEYCLOAK_CLIENT_SECRET=change-me \
  KEYCLOAK_CLIENT_SECRET=change-me
