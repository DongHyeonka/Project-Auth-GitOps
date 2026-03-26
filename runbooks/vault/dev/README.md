## Vault Dev Bootstrap

이 문서는 dev 환경의 **workload Vault** 를 Terraform으로 선언적으로 bootstrap / reconcile 하는 절차를 정리합니다.

사전 조건:

- [vault-transit bootstrap runbook](/home/donghyeon/dev/Project-Auth-GitOps/runbooks/vault-transit/dev/README.md) 을 먼저 완료해야 합니다.
- `vault` namespace에 `vault-transit-seal` Secret 이 준비되어 있어야 workload Vault 가 auto-unseal 됩니다.

현재 저장소의 source of truth 는 `terraform/vault/dev` 입니다.
기존 `bootstrap-runbook.sh`, `reconcile.sh`, `populate-kv.sh` 는 모두 이 Terraform apply 를 호출하는 thin wrapper 입니다.

### 준비물

- `kubectl`
- `vault`
- `jq`
- `terraform`
- dev 클러스터에 접근 가능한 kubeconfig

### 1. Vault 포트 포워딩

```bash
kubectl port-forward -n vault svc/vault 8200:8200
```

### 2. Vault init / bootstrap token 준비

```bash
export VAULT_ADDR=http://127.0.0.1:8200
vault operator init -format=json > .local/vault-dev-init.json
export TF_VAR_workload_vault_addr="$VAULT_ADDR"
export TF_VAR_workload_vault_token="$(jq -r '.root_token' .local/vault-dev-init.json)"
```

Transit auto-unseal 구조이므로 정상 상태에서는 `vault operator unseal` 을 반복하지 않습니다.

### 3. Provider seed credential 연결

workload Terraform 은 provider Vault 에서 seed 값을 읽고, 생성한 workload workflow AppRole credential 을 다시 provider Vault bootstrap path 로 써넣습니다.

```bash
export TF_VAR_transit_vault_addr=http://127.0.0.1:18200
export TF_VAR_transit_vault_token="$(VAULT_ADDR="$TF_VAR_transit_vault_addr" vault write -field=token auth/approle/login \
  role_id="<vault-transit-workflow-role-id>" \
  secret_id="<vault-transit-workflow-secret-id>")"
```

### 4. Terraform bootstrap / reconcile

```bash
terraform -chdir=terraform/vault/dev init -input=false
terraform -chdir=terraform/vault/dev apply -input=false -auto-approve
```

이 apply 는 아래를 선언적으로 맞춥니다.

- `kv`, `database`, `transit` mount 활성화
- Kubernetes auth backend / role reconcile
- AppRole backend / workflow AppRole reconcile
- dev runtime KV 를 provider Vault seed 에 맞춰 동기화
- JWT transit key 생성
- Postgres database backend / dynamic role 정의
- `kv/dev/workload/bootstrap` 에 workload workflow AppRole credential publish

필요하면 output 으로 workload workflow AppRole 값을 직접 확인할 수 있습니다.

```bash
terraform -chdir=terraform/vault/dev output workflow_role_id
terraform -chdir=terraform/vault/dev output -raw workflow_secret_id
```

### 정책 분리

현재 dev 정책은 아래처럼 역할별로 나눕니다.

- `auth-server-dev`
  이유: 앱 런타임은 `platform/postgres/auth-server`, `platform/keycloak/client-auth-server`, JWT transit signing만 접근하면 충분합니다.
- `auth-db-migration-dev`
  이유: migration job 은 `database/creds/auth-db-migration-dev` 로 짧은 DB credential 을 받아 실행합니다.
- `postgres-dev`
  이유: DB pod 는 `platform/postgres/superuser`, `platform/postgres/auth-server`, `platform/postgres/keycloak` 만 읽으면 됩니다.
- `keycloak-dev`
  이유: Keycloak pod 는 `platform/postgres/keycloak`, `platform/keycloak/bootstrap-admin` 만 읽으면 됩니다.
- `keycloak-client-sync-dev`
  이유: client sync job 은 `platform/keycloak/bootstrap-admin`, `platform/keycloak/client-auth-server` 만 읽으면 됩니다.
- `workload-automation-dev`
  이유: Terraform apply 가 policy, role, auth, transit, KV, AppRole, database 설정을 모두 reconcile 합니다.
- `platform-admin-dev`
  이유: 사람이 비상 복구나 수동 운영 작업을 할 때 쓰는 운영자 정책입니다.
- `postgres-operator-dev`
  이유: 사람이 dev DB 에 직접 접속할 때는 `database/creds/postgres-operator-dev` 만 읽는 짧은 토큰으로 제한합니다.
- `keycloak-operator-dev`
  이유: 사람이 Keycloak 에 직접 로그인할 때는 bootstrap admin credential 만 읽는 짧은 토큰으로 제한합니다.

### 자동화용 CI Secret

`vault-dev-reconcile` workflow 를 사용하려면 최소 아래 secret 이 필요합니다.

- `KUBECONFIG_DEV_B64`
- `VAULT_TRANSIT_DEV_ROLE_ID`
- `VAULT_TRANSIT_DEV_SECRET_ID`

권장 흐름은 아래와 같습니다.

1. `vault-transit` runbook 으로 provider Vault 를 1회 init / unseal / bootstrap 합니다.
2. provider Vault 에 app seed 값을 입력합니다.
3. workload Vault 를 1회 init 합니다.
4. `terraform/vault/dev` 를 root token 으로 1회 apply 합니다.
5. 이 apply 가 workload workflow AppRole credential 을 `kv/dev/workload/bootstrap` 에 써넣습니다.
6. 이후부터는 workflow 가 provider bootstrap 확인, workload Terraform apply, Argo CD app apply 를 자동 수행합니다.

### 정적 seed 로 최초 1회 넣어야 하는 값

아래 값들은 최초 1회 사람이 입력하거나 상위 secret source 에서 sync 해야 합니다.

- `kv/dev/workload/platform/postgres/superuser`
  값: `POSTGRES_SUPERUSER_PASSWORD`
- `kv/dev/workload/platform/postgres/auth-server`
  값: `APP_DATASOURCE_USERNAME`, `APP_DATASOURCE_PASSWORD`, `AUTH_DB_PASSWORD`
- `kv/dev/workload/platform/postgres/keycloak`
  값: `KEYCLOAK_DB_PASSWORD`
- `kv/dev/workload/platform/keycloak/bootstrap-admin`
  값: `KC_BOOTSTRAP_ADMIN_PASSWORD`
- `kv/dev/workload/platform/keycloak/client-auth-server`
  값: `APP_SECURITY_OAUTH2_KEYCLOAK_CLIENT_SECRET`, `KEYCLOAK_CLIENT_SECRET`

이 값들은 provider Vault seed path 가 source of truth 이고, workload Terraform apply 가 이를 workload Vault KV 로 동기화합니다.

### 사람 직접 접근용 토큰 발급

장기 운영자 토큰은 Terraform state 에 저장하지 않습니다.
필요할 때 privileged token 으로 `platform-admin-dev` 토큰을 짧게 발급한 뒤 아래 스크립트를 사용합니다.

```bash
export VAULT_ADDR=http://127.0.0.1:8200
export VAULT_TOKEN=<privileged-token>

vault token create -orphan -policy=platform-admin-dev -ttl=1h
```

발급된 `platform-admin-dev` 토큰으로:

```bash
export VAULT_TOKEN=<platform-admin-dev-token>
./scripts/vault/dev/issue-operator-tokens.sh
```

이후:

- `postgres-operator-dev`: `vault read database/creds/postgres-operator-dev`
- `keycloak-operator-dev`: `vault kv get kv/dev/platform/keycloak/bootstrap-admin`

를 수행해 dev 접속 정보를 확인할 수 있습니다.

### 주의

- `terraform/vault/dev` 의 local state 는 [`.terraform-state/vault-dev.tfstate`](/home/donghyeon/dev/Project-Auth-GitOps/.terraform-state/vault-dev.tfstate) 에 저장됩니다.
- Vault provider state 에는 민감한 값이 들어가므로 self-hosted runner 와 로컬 작업 디렉터리를 동일하게 보호해야 합니다.
