variable "approle_auth_path" {
  description = "Path where the workload AppRole auth backend is mounted."
  type        = string
  default     = "approle"
}

variable "auth_db_migration_default_ttl_seconds" {
  description = "Default TTL, in seconds, for auth DB migration credentials."
  type        = number
  default     = 3600
}

variable "auth_db_migration_max_ttl_seconds" {
  description = "Maximum TTL, in seconds, for auth DB migration credentials."
  type        = number
  default     = 86400
}

variable "auth_db_role" {
  description = "Existing PostgreSQL role granted to dynamic auth users."
  type        = string
  default     = "project_auth"
}

variable "database_config_name" {
  description = "Name of the Vault database connection configuration."
  type        = string
  default     = "platform-postgres-dev"
}

variable "database_mount_path" {
  description = "Mount path for the workload database secrets engine."
  type        = string
  default     = "database"
}

variable "jwt_transit_key_name" {
  description = "Transit key name used for JWT signing."
  type        = string
  default     = "project-auth-jwt"
}

variable "kubernetes_auth_path" {
  description = "Path where the Kubernetes auth backend is mounted."
  type        = string
  default     = "kubernetes"
}

variable "kubernetes_ca_cert" {
  description = "CA certificate used by the workload Vault Kubernetes auth backend."
  type        = string
  default     = null
  sensitive   = true
}

variable "kubernetes_token_reviewer_jwt" {
  description = "Reviewer JWT used by the workload Vault Kubernetes auth backend."
  type        = string
  default     = null
  sensitive   = true
}

variable "kubernetes_role_ttl_seconds" {
  description = "TTL, in seconds, granted to workload Kubernetes auth logins."
  type        = number
  default     = 86400
}

variable "kv_mount_path" {
  description = "Mount path for the workload KV-v2 engine."
  type        = string
  default     = "kv"
}

variable "postgres_admin_database" {
  description = "Administrative PostgreSQL database used by the database secret engine."
  type        = string
  default     = "postgres"
}

variable "postgres_host" {
  description = "DNS name of the platform PostgreSQL service."
  type        = string
  default     = "postgres-0.postgres.platform.svc.cluster.local"
}

variable "postgres_operator_default_ttl_seconds" {
  description = "Default TTL, in seconds, for the operator PostgreSQL role."
  type        = number
  default     = 3600
}

variable "postgres_operator_max_ttl_seconds" {
  description = "Maximum TTL, in seconds, for the operator PostgreSQL role."
  type        = number
  default     = 28800
}

variable "postgres_port" {
  description = "Port of the platform PostgreSQL service."
  type        = number
  default     = 5432
}

variable "postgres_superuser" {
  description = "PostgreSQL superuser used by Vault database secrets."
  type        = string
  default     = "postgres"
}

variable "seed_kv_mount_path" {
  description = "Mount path for the provider KV-v2 seed data."
  type        = string
  default     = "kv"
}

variable "transit_mount_path" {
  description = "Mount path for the workload transit engine."
  type        = string
  default     = "transit"
}

variable "transit_vault_addr" {
  description = "Address of the vault-transit API."
  type        = string
  default     = "http://127.0.0.1:18200"
}

variable "transit_vault_token" {
  description = "Token used to read provider seed data and publish workload bootstrap credentials."
  type        = string
  sensitive   = true
}

variable "workflow_token_max_ttl_seconds" {
  description = "Maximum TTL, in seconds, for the workload workflow AppRole login token."
  type        = number
  default     = 14400
}

variable "workflow_token_ttl_seconds" {
  description = "Default TTL, in seconds, for the workload workflow AppRole login token."
  type        = number
  default     = 3600
}

variable "workload_vault_addr" {
  description = "Address of the workload Vault API."
  type        = string
  default     = "http://127.0.0.1:8200"
}

variable "workload_vault_token" {
  description = "Privileged token used to reconcile workload Vault."
  type        = string
  sensitive   = true
}
