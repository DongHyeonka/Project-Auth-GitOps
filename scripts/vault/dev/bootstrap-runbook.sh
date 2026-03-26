#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

source "${SCRIPT_DIR}/provider-lib.sh"
source "${SCRIPT_DIR}/workload-auth-lib.sh"

if ! command -v terraform >/dev/null 2>&1; then
  echo "terraform CLI is required" >&2
  exit 1
fi

export VAULT_WORKLOAD_ADDR="${VAULT_WORKLOAD_ADDR:-${VAULT_ADDR:-http://127.0.0.1:8200}}"
export VAULT_TRANSIT_ADDR="${VAULT_TRANSIT_ADDR:-http://127.0.0.1:18200}"
export TF_VAR_workload_vault_addr="$VAULT_WORKLOAD_ADDR"
export TF_VAR_workload_vault_token="$(workload_vault_token)"
export TF_VAR_transit_vault_addr="$VAULT_TRANSIT_ADDR"
export TF_VAR_transit_vault_token="$(provider_vault_token)"

mkdir -p "${REPO_ROOT}/.terraform-state"

terraform -chdir="${REPO_ROOT}/terraform/vault/dev" init -input=false
terraform -chdir="${REPO_ROOT}/terraform/vault/dev" apply -input=false -auto-approve
