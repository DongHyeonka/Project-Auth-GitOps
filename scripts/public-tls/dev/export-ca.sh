#!/usr/bin/env bash
set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
SOURCE_CERT="${REPO_ROOT}/runbooks/public-tls/dev/project-auth-dev-public-ca.crt"
DEST_PATH="${1:-${REPO_ROOT}/.local/project-auth-dev-public-ca.crt}"

mkdir -p "$(dirname "${DEST_PATH}")"
cp "${SOURCE_CERT}" "${DEST_PATH}"
chmod 0644 "${DEST_PATH}"

printf '%s\n' "${DEST_PATH}"
