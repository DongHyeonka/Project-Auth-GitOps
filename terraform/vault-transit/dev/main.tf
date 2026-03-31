terraform {
  required_version = ">= 1.6.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.32"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 4.8.0"
    }
  }

  backend "local" {
    path = "../../../.terraform-state/vault-transit-dev.tfstate"
  }
}

provider "vault" {
  address          = var.vault_addr
  skip_child_token = true
  token            = var.vault_token
}

provider "kubernetes" {
  config_path = var.kubeconfig_path
}

locals {
  workflow_policy_path = "${path.module}/../../../runbooks/vault-transit/dev/policies/vault-transit-automation-dev.hcl"
  workload_policy_path = "${path.module}/../../../runbooks/vault-transit/dev/policies/workload-vault-transit-dev.hcl"
  admin_policy_path    = "${path.module}/../../../runbooks/vault-transit/dev/policies/vault-transit-admin-dev.hcl"
}

resource "vault_mount" "kv" {
  path = var.kv_mount_path
  type = "kv"
  options = {
    version = "2"
  }

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [type, options]
  }
}

resource "vault_mount" "transit" {
  path = var.transit_mount_path
  type = "transit"

  lifecycle {
    prevent_destroy = true
  }
}

resource "vault_transit_secret_backend_key" "workload_unseal" {
  backend = vault_mount.transit.path
  name    = var.seal_key_name
  type    = "aes256-gcm96"
}

resource "vault_policy" "workload_vault_transit_dev" {
  name   = var.workload_policy_name
  policy = file(local.workload_policy_path)
}

resource "vault_policy" "vault_transit_admin_dev" {
  name   = var.admin_policy_name
  policy = file(local.admin_policy_path)
}

resource "vault_policy" "vault_transit_automation_dev" {
  name   = var.workflow_policy_name
  policy = file(local.workflow_policy_path)
}

resource "vault_auth_backend" "approle" {
  path = var.approle_auth_path
  type = "approle"
}

resource "vault_approle_auth_backend_role" "workflow" {
  backend            = vault_auth_backend.approle.path
  role_name          = var.workflow_role_name
  secret_id_num_uses = 0
  secret_id_ttl      = 0
  token_max_ttl      = var.workflow_token_max_ttl_seconds
  token_policies     = [vault_policy.vault_transit_automation_dev.name]
  token_ttl          = var.workflow_token_ttl_seconds
}

resource "vault_approle_auth_backend_role_secret_id" "workflow" {
  backend   = vault_auth_backend.approle.path
  role_name = vault_approle_auth_backend_role.workflow.role_name
}

resource "vault_token" "seal" {
  display_name = "workload-vault-dev-unseal"
  no_parent    = true
  period       = var.seal_token_period
  policies     = [vault_policy.workload_vault_transit_dev.name]
  renewable    = true

  lifecycle {
    ignore_changes = all
  }
}

resource "kubernetes_secret_v1" "vault_transit_seal" {
  wait_for_service_account_token = true

  metadata {
    name      = var.target_secret_name
    namespace = var.target_namespace
  }

  data = {
    VAULT_TRANSIT_SEAL_TOKEN = vault_token.seal.client_token
  }

  type = "Opaque"
}

output "workflow_role_id" {
  description = "Vault transit workflow AppRole role_id."
  value       = vault_approle_auth_backend_role.workflow.role_id
}

output "workflow_secret_id" {
  description = "Vault transit workflow AppRole secret_id."
  value       = vault_approle_auth_backend_role_secret_id.workflow.secret_id
  sensitive   = true
}

output "vault_transit_seal_token" {
  description = "Periodic seal token written into the vault-transit-seal Kubernetes Secret."
  value       = vault_token.seal.client_token
  sensitive   = true
}
