terraform {
  required_version = ">= 1.6.0"

  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 4.8.0"
    }
  }

  backend "local" {
    path = "../../../.terraform-state/vault-dev.tfstate"
  }
}

provider "vault" {
  address          = var.workload_vault_addr
  skip_child_token = true
  token            = var.workload_vault_token
}

provider "vault" {
  alias            = "transit"
  address          = var.transit_vault_addr
  skip_child_token = true
  token            = var.transit_vault_token
}

locals {
  policy_dir = "${path.module}/../../../runbooks/vault/dev/policies"

  auth_server_policy_name           = "auth-server-dev"
  auth_db_migration_policy_name     = "auth-db-migration-dev"
  postgres_policy_name              = "postgres-dev"
  keycloak_policy_name              = "keycloak-dev"
  keycloak_client_sync_policy_name  = "keycloak-client-sync-dev"
  postgres_operator_policy_name     = "postgres-operator-dev"
  keycloak_operator_policy_name     = "keycloak-operator-dev"
  platform_admin_policy_name        = "platform-admin-dev"
  workload_automation_policy_name   = "workload-automation-dev"
  workload_workflow_role_name       = "workload-dev-workflow"
  auth_db_migration_role_name       = "auth-db-migration-dev"
  postgres_operator_role_name       = "postgres-operator-dev"

  migration_creation_statements = [
    <<-EOT
    CREATE ROLE "{{name}}" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';
    GRANT "${var.auth_db_role}" TO "{{name}}";
    EOT
  ]

  migration_revocation_statements = [
    <<-EOT
    REASSIGN OWNED BY "{{name}}" TO "${var.auth_db_role}";
    DROP OWNED BY "{{name}}";
    REVOKE "${var.auth_db_role}" FROM "{{name}}";
    DROP ROLE IF EXISTS "{{name}}";
    EOT
  ]

  operator_creation_statements = [
    <<-EOT
    CREATE ROLE "{{name}}" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';
    GRANT "${var.auth_db_role}" TO "{{name}}";
    EOT
  ]

  operator_revocation_statements = [
    <<-EOT
    REASSIGN OWNED BY "{{name}}" TO "${var.auth_db_role}";
    DROP OWNED BY "{{name}}";
    REVOKE "${var.auth_db_role}" FROM "{{name}}";
    DROP ROLE IF EXISTS "{{name}}";
    EOT
  ]
}

resource "vault_mount" "kv" {
  path = var.kv_mount_path
  type = "kv"
  options = {
    version = "2"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "vault_mount" "database" {
  path = var.database_mount_path
  type = "database"

  lifecycle {
    prevent_destroy = true
  }
}

resource "vault_mount" "transit" {
  path = var.transit_mount_path
  type = "transit"

  lifecycle {
    prevent_destroy = true
  }
}

resource "vault_auth_backend" "kubernetes" {
  path = var.kubernetes_auth_path
  type = "kubernetes"
}

resource "vault_kubernetes_auth_backend_config" "cluster" {
  backend                = vault_auth_backend.kubernetes.path
  disable_iss_validation = true
  kubernetes_host        = "https://kubernetes.default.svc.cluster.local:443"
  kubernetes_ca_cert     = var.kubernetes_ca_cert
  token_reviewer_jwt     = var.kubernetes_token_reviewer_jwt
}

resource "vault_auth_backend" "approle" {
  path = var.approle_auth_path
  type = "approle"
}

resource "vault_policy" "auth_server" {
  name   = local.auth_server_policy_name
  policy = file("${local.policy_dir}/auth-server-dev.hcl")
}

resource "vault_policy" "auth_db_migration" {
  name   = local.auth_db_migration_policy_name
  policy = file("${local.policy_dir}/auth-db-migration-dev.hcl")
}

resource "vault_policy" "postgres" {
  name   = local.postgres_policy_name
  policy = file("${local.policy_dir}/postgres-dev.hcl")
}

resource "vault_policy" "keycloak" {
  name   = local.keycloak_policy_name
  policy = file("${local.policy_dir}/keycloak-dev.hcl")
}

resource "vault_policy" "keycloak_client_sync" {
  name   = local.keycloak_client_sync_policy_name
  policy = file("${local.policy_dir}/keycloak-client-sync-dev.hcl")
}

resource "vault_policy" "postgres_operator" {
  name   = local.postgres_operator_policy_name
  policy = file("${local.policy_dir}/postgres-operator-dev.hcl")
}

resource "vault_policy" "keycloak_operator" {
  name   = local.keycloak_operator_policy_name
  policy = file("${local.policy_dir}/keycloak-operator-dev.hcl")
}

resource "vault_policy" "platform_admin" {
  name   = local.platform_admin_policy_name
  policy = file("${local.policy_dir}/platform-admin-dev.hcl")
}

resource "vault_policy" "workload_automation" {
  name   = local.workload_automation_policy_name
  policy = file("${local.policy_dir}/workload-automation-dev.hcl")
}

resource "vault_kubernetes_auth_backend_role" "auth_server" {
  backend                          = vault_auth_backend.kubernetes.path
  bound_service_account_names      = ["auth-server"]
  bound_service_account_namespaces = ["auth-dev"]
  role_name                        = local.auth_server_policy_name
  token_policies                   = [vault_policy.auth_server.name]
  token_ttl                        = var.kubernetes_role_ttl_seconds
}

resource "vault_kubernetes_auth_backend_role" "auth_db_migration" {
  backend                          = vault_auth_backend.kubernetes.path
  bound_service_account_names      = ["auth-db-migration"]
  bound_service_account_namespaces = ["auth-dev"]
  role_name                        = local.auth_db_migration_policy_name
  token_policies                   = [vault_policy.auth_db_migration.name]
  token_ttl                        = var.kubernetes_role_ttl_seconds
}

resource "vault_kubernetes_auth_backend_role" "postgres" {
  backend                          = vault_auth_backend.kubernetes.path
  bound_service_account_names      = ["postgres"]
  bound_service_account_namespaces = ["platform"]
  role_name                        = local.postgres_policy_name
  token_policies                   = [vault_policy.postgres.name]
  token_ttl                        = var.kubernetes_role_ttl_seconds
}

resource "vault_kubernetes_auth_backend_role" "keycloak" {
  backend                          = vault_auth_backend.kubernetes.path
  bound_service_account_names      = ["keycloak"]
  bound_service_account_namespaces = ["platform"]
  role_name                        = local.keycloak_policy_name
  token_policies                   = [vault_policy.keycloak.name]
  token_ttl                        = var.kubernetes_role_ttl_seconds
}

resource "vault_kubernetes_auth_backend_role" "keycloak_client_sync" {
  backend                          = vault_auth_backend.kubernetes.path
  bound_service_account_names      = ["keycloak-client-sync"]
  bound_service_account_namespaces = ["platform"]
  role_name                        = local.keycloak_client_sync_policy_name
  token_policies                   = [vault_policy.keycloak_client_sync.name]
  token_ttl                        = var.kubernetes_role_ttl_seconds
}

resource "vault_transit_secret_backend_key" "project_auth_jwt" {
  backend = vault_mount.transit.path
  name    = var.jwt_transit_key_name
  type    = "rsa-2048"
}

resource "vault_approle_auth_backend_role" "workflow" {
  backend            = vault_auth_backend.approle.path
  role_name          = local.workload_workflow_role_name
  secret_id_num_uses = 0
  secret_id_ttl      = 0
  token_max_ttl      = var.workflow_token_max_ttl_seconds
  token_policies     = [vault_policy.workload_automation.name]
  token_ttl          = var.workflow_token_ttl_seconds
}

resource "vault_approle_auth_backend_role_secret_id" "workflow" {
  backend   = vault_auth_backend.approle.path
  role_name = vault_approle_auth_backend_role.workflow.role_name
}

data "vault_kv_secret_v2" "provider_postgres_superuser" {
  provider = vault.transit
  mount    = var.seed_kv_mount_path
  name     = "dev/workload/platform/postgres/superuser"
}

data "vault_kv_secret_v2" "provider_postgres_auth_server" {
  provider = vault.transit
  mount    = var.seed_kv_mount_path
  name     = "dev/workload/platform/postgres/auth-server"
}

data "vault_kv_secret_v2" "provider_postgres_keycloak" {
  provider = vault.transit
  mount    = var.seed_kv_mount_path
  name     = "dev/workload/platform/postgres/keycloak"
}

data "vault_kv_secret_v2" "provider_keycloak_bootstrap_admin" {
  provider = vault.transit
  mount    = var.seed_kv_mount_path
  name     = "dev/workload/platform/keycloak/bootstrap-admin"
}

data "vault_kv_secret_v2" "provider_keycloak_client_auth_server" {
  provider = vault.transit
  mount    = var.seed_kv_mount_path
  name     = "dev/workload/platform/keycloak/client-auth-server"
}

resource "vault_kv_secret_v2" "workload_bootstrap" {
  provider = vault.transit
  mount    = var.seed_kv_mount_path
  name     = "dev/workload/bootstrap"
  data_json = jsonencode({
    VAULT_WORKLOAD_DEV_ROLE_ID   = vault_approle_auth_backend_role.workflow.role_id
    VAULT_WORKLOAD_DEV_SECRET_ID = vault_approle_auth_backend_role_secret_id.workflow.secret_id
  })
}

resource "vault_kv_secret_v2" "platform_postgres_superuser" {
  mount = vault_mount.kv.path
  name  = "dev/platform/postgres/superuser"
  data_json = jsonencode({
    POSTGRES_SUPERUSER_PASSWORD = data.vault_kv_secret_v2.provider_postgres_superuser.data["POSTGRES_SUPERUSER_PASSWORD"]
  })
}

resource "vault_kv_secret_v2" "platform_postgres_auth_server" {
  mount = vault_mount.kv.path
  name  = "dev/platform/postgres/auth-server"
  data_json = jsonencode({
    APP_DATASOURCE_PASSWORD = data.vault_kv_secret_v2.provider_postgres_auth_server.data["APP_DATASOURCE_PASSWORD"]
    APP_DATASOURCE_USERNAME = data.vault_kv_secret_v2.provider_postgres_auth_server.data["APP_DATASOURCE_USERNAME"]
    AUTH_DB_PASSWORD        = data.vault_kv_secret_v2.provider_postgres_auth_server.data["AUTH_DB_PASSWORD"]
  })
}

resource "vault_kv_secret_v2" "platform_postgres_keycloak" {
  mount = vault_mount.kv.path
  name  = "dev/platform/postgres/keycloak"
  data_json = jsonencode({
    KEYCLOAK_DB_PASSWORD = data.vault_kv_secret_v2.provider_postgres_keycloak.data["KEYCLOAK_DB_PASSWORD"]
  })
}

resource "vault_kv_secret_v2" "platform_keycloak_bootstrap_admin" {
  mount = vault_mount.kv.path
  name  = "dev/platform/keycloak/bootstrap-admin"
  data_json = jsonencode({
    KC_BOOTSTRAP_ADMIN_PASSWORD = data.vault_kv_secret_v2.provider_keycloak_bootstrap_admin.data["KC_BOOTSTRAP_ADMIN_PASSWORD"]
  })
}

resource "vault_kv_secret_v2" "platform_keycloak_client_auth_server" {
  mount = vault_mount.kv.path
  name  = "dev/platform/keycloak/client-auth-server"
  data_json = jsonencode({
    APP_SECURITY_OAUTH2_KEYCLOAK_CLIENT_SECRET = data.vault_kv_secret_v2.provider_keycloak_client_auth_server.data["APP_SECURITY_OAUTH2_KEYCLOAK_CLIENT_SECRET"]
    KEYCLOAK_CLIENT_SECRET                     = data.vault_kv_secret_v2.provider_keycloak_client_auth_server.data["KEYCLOAK_CLIENT_SECRET"]
  })
}

resource "vault_database_secret_backend_connection" "platform_postgres" {
  allowed_roles     = [local.auth_db_migration_role_name, local.postgres_operator_role_name]
  backend           = vault_mount.database.path
  name              = var.database_config_name
  plugin_name       = "postgresql-database-plugin"
  verify_connection = false

  postgresql {
    connection_url = "postgresql://{{username}}:{{password}}@${var.postgres_host}:${var.postgres_port}/${var.postgres_admin_database}?sslmode=disable"
    password       = vault_kv_secret_v2.platform_postgres_superuser.data["POSTGRES_SUPERUSER_PASSWORD"]
    username       = var.postgres_superuser
  }
}

resource "vault_database_secret_backend_role" "auth_db_migration" {
  backend                = vault_mount.database.path
  creation_statements    = local.migration_creation_statements
  db_name                = vault_database_secret_backend_connection.platform_postgres.name
  default_ttl            = var.auth_db_migration_default_ttl_seconds
  max_ttl                = var.auth_db_migration_max_ttl_seconds
  name                   = local.auth_db_migration_role_name
  revocation_statements  = local.migration_revocation_statements
}

resource "vault_database_secret_backend_role" "postgres_operator" {
  backend                = vault_mount.database.path
  creation_statements    = local.operator_creation_statements
  db_name                = vault_database_secret_backend_connection.platform_postgres.name
  default_ttl            = var.postgres_operator_default_ttl_seconds
  max_ttl                = var.postgres_operator_max_ttl_seconds
  name                   = local.postgres_operator_role_name
  revocation_statements  = local.operator_revocation_statements
}

output "workflow_role_id" {
  description = "Workload Vault workflow AppRole role_id."
  value       = vault_approle_auth_backend_role.workflow.role_id
}

output "workflow_secret_id" {
  description = "Workload Vault workflow AppRole secret_id."
  value       = vault_approle_auth_backend_role_secret_id.workflow.secret_id
  sensitive   = true
}
