variable "admin_policy_name" {
  description = "Name of the operator policy kept for manual vault-transit maintenance."
  type        = string
  default     = "vault-transit-admin-dev"
}

variable "approle_auth_path" {
  description = "Path where the AppRole auth backend is mounted."
  type        = string
  default     = "approle"
}

variable "kubeconfig_path" {
  description = "Path to the kubeconfig used for managing the seal Secret."
  type        = string
  default     = "~/.kube/config"
}

variable "kv_mount_path" {
  description = "Mount path for the provider KV-v2 engine."
  type        = string
  default     = "kv"
}

variable "seal_key_name" {
  description = "Transit key used by workload Vault auto-unseal."
  type        = string
  default     = "workload-vault-dev-unseal"
}

variable "seal_token_period" {
  description = "Periodic renewal interval for the workload auto-unseal token."
  type        = string
  default     = "24h"
}

variable "target_namespace" {
  description = "Namespace that receives the vault-transit seal Secret."
  type        = string
  default     = "vault"
}

variable "target_secret_name" {
  description = "Name of the Kubernetes Secret holding the workload auto-unseal token."
  type        = string
  default     = "vault-transit-seal"
}

variable "transit_mount_path" {
  description = "Mount path for the provider transit engine."
  type        = string
  default     = "transit"
}

variable "vault_addr" {
  description = "Address of the vault-transit API."
  type        = string
  default     = "http://127.0.0.1:18200"
}

variable "vault_token" {
  description = "Privileged token used to reconcile the vault-transit configuration."
  type        = string
  sensitive   = true
}

variable "workflow_policy_name" {
  description = "Policy granted to the vault-transit workflow AppRole."
  type        = string
  default     = "vault-transit-automation-dev"
}

variable "workflow_role_name" {
  description = "Name of the workflow AppRole used by CI."
  type        = string
  default     = "vault-transit-dev-workflow"
}

variable "workflow_token_max_ttl_seconds" {
  description = "Maximum TTL, in seconds, for the workflow AppRole login token."
  type        = number
  default     = 14400
}

variable "workflow_token_ttl_seconds" {
  description = "Default TTL, in seconds, for the workflow AppRole login token."
  type        = number
  default     = 3600
}

variable "workload_policy_name" {
  description = "Policy name granted to the workload Vault auto-unseal token."
  type        = string
  default     = "workload-vault-transit-dev"
}
