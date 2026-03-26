#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

source "${SCRIPT_DIR}/../../vault/dev/provider-lib.sh"

if ! command -v terraform >/dev/null 2>&1; then
  echo "terraform CLI is required" >&2
  exit 1
fi

export VAULT_TRANSIT_ADDR="${VAULT_TRANSIT_ADDR:-${VAULT_ADDR:-http://127.0.0.1:18200}}"
export TF_VAR_vault_addr="$VAULT_TRANSIT_ADDR"
export TF_VAR_vault_token="$(provider_vault_token)"

if [[ -n "${SEAL_KEY_NAME:-}" ]]; then
  export TF_VAR_seal_key_name="$SEAL_KEY_NAME"
fi

if [[ -n "${SEAL_TOKEN_PERIOD:-}" ]]; then
  export TF_VAR_seal_token_period="$SEAL_TOKEN_PERIOD"
fi

if [[ -n "${TARGET_NAMESPACE:-}" ]]; then
  export TF_VAR_target_namespace="$TARGET_NAMESPACE"
fi

if [[ -n "${TARGET_SECRET_NAME:-}" ]]; then
  export TF_VAR_target_secret_name="$TARGET_SECRET_NAME"
fi

if [[ -n "${WORKFLOW_POLICY_NAME:-}" ]]; then
  export TF_VAR_workflow_policy_name="$WORKFLOW_POLICY_NAME"
fi

if [[ -n "${WORKFLOW_ROLE_NAME:-}" ]]; then
  export TF_VAR_workflow_role_name="$WORKFLOW_ROLE_NAME"
fi

mkdir -p "${REPO_ROOT}/.terraform-state"

terraform -chdir="${REPO_ROOT}/terraform/vault-transit/dev" init -input=false
terraform -chdir="${REPO_ROOT}/terraform/vault-transit/dev" apply -input=false -auto-approve
