#!/usr/bin/env bash

set -euo pipefail

for cmd in kubectl; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "$cmd is required" >&2
    exit 1
  fi
done

kubectl apply -f argocd/projects/dev
kubectl apply -f argocd/applications/dev/infra/platform.yaml
kubectl apply -f argocd/applications/dev/apps
