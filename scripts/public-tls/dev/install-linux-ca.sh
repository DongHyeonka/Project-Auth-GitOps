#!/usr/bin/env bash
set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
SOURCE_CERT="${REPO_ROOT}/runbooks/public-tls/dev/project-auth-dev-public-ca.crt"
DEST_CERT="${DEST_CERT:-/usr/local/share/ca-certificates/project-auth-dev-public-ca.crt}"

if [[ "${EUID}" -ne 0 ]]; then
  echo "run as root: sudo $0" >&2
  exit 1
fi

install -D -m 0644 "${SOURCE_CERT}" "${DEST_CERT}"
update-ca-certificates

printf 'installed %s\n' "${DEST_CERT}"
