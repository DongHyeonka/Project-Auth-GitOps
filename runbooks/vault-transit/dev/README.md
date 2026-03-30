## Vault Transit Dev Bootstrap

이 문서는 dev 환경의 **unseal provider Vault** 를 Terraform으로 선언적으로 bootstrap 하는 절차를 정리합니다.

이 Vault는 애플리케이션 secret을 직접 저장하지 않고, 업무용 Vault의 transit auto-unseal provider와 workload seed source 역할만 담당합니다.

### 준비물

- `kubectl`
- `vault`
- `jq`
- `terraform`
- dev 클러스터에 접근 가능한 kubeconfig

### 0. 기동 상태 확인

`init / unseal` 전에 먼저 `vault-transit` pod가 실제로 기동 가능한 상태인지 확인합니다.

```bash
kubectl -n vault-transit get deploy,pods,svc,pvc
kubectl -n vault-transit rollout status deploy/vault-transit --timeout=180s
```

정상 기준:

- `deployment/vault-transit` 이 `1/1 Ready`
- pod가 `Running`
- `CrashLoopBackOff` 가 아님

기동이 안 되면 아래를 먼저 봅니다.

```bash
kubectl -n vault-transit describe deployment vault-transit
kubectl -n vault-transit logs deploy/vault-transit --tail=200
kubectl -n vault-transit get events --sort-by=.lastTimestamp | tail -n 30
```

최근 dev 기준 대표 원인은 아래였습니다.

- `Cluster address must be set when using raft storage`
  원인: raft storage 사용 시 `api_addr`, `cluster_addr`, listener `cluster_address` 가 빠져 있었음
- `Could not chown /vault/config`
  원인: ConfigMap mount가 read-only 인데 이미지 entrypoint가 해당 경로를 `chown` 하려 함

현재 base manifest는 위 이슈를 피하기 위해:

- `api_addr`, `cluster_addr`, `cluster_address` 추가
- service/deployment `8201` cluster 포트 추가
- deployment `strategy: Recreate`
- `/vault/config/vault.hcl` 을 `/tmp/vault.hcl` 로 복사 후 `vault server` 실행

형태로 정리되어 있습니다.

### 1. 포트 포워딩

```bash
kubectl port-forward -n vault-transit svc/vault-transit 18200:8200
```

### 2. init / unseal

```bash
export VAULT_ADDR=http://127.0.0.1:18200
vault operator init -format=json > .local/vault-transit-dev-init.json
vault operator unseal "$(jq -r '.unseal_keys_b64[0]' .local/vault-transit-dev-init.json)"
export TF_VAR_vault_token="$(jq -r '.root_token' .local/vault-transit-dev-init.json)"
export TF_VAR_vault_addr="$VAULT_ADDR"
```

### 3. Terraform bootstrap

```bash
terraform -chdir=terraform/vault-transit/dev init -input=false
terraform -chdir=terraform/vault-transit/dev apply -input=false -auto-approve
```

이 apply 는 아래를 선언적으로 맞춥니다.

- `kv` / `transit` secrets engine 활성화
- workload Vault auto-unseal key 생성
- `workload-vault-transit-dev`, `vault-transit-admin-dev`, `vault-transit-automation-dev` policy reconcile
- workflow용 `vault-transit-dev-workflow` AppRole reconcile
- `vault/vault-transit-seal` Kubernetes Secret 갱신

필요한 CI credential은 Terraform output 으로 확인합니다.

```bash
terraform -chdir=terraform/vault-transit/dev output workflow_role_id
terraform -chdir=terraform/vault-transit/dev output -raw workflow_secret_id
```

이 두 값은 `VAULT_TRANSIT_DEV_ROLE_ID`, `VAULT_TRANSIT_DEV_SECRET_ID` 로 CI secret store 에 저장합니다.

### 4. 이후 역할

- 업무용 Vault([vault app](/home/donghyeon/dev/Project-Auth-GitOps/argocd/applications/dev/infra/vault.yaml)) 는 `vault-transit-seal` Secret 의 토큰으로 transit auto-unseal 을 수행합니다.
- `vault-transit` provider Vault 자체는 dev/on-prem 전제에서 여전히 **수동 unseal** 입니다.
- self-hosted runner workflow는 provider AppRole 로 로그인한 뒤 `terraform/vault-transit/dev`, `terraform/vault/dev` 를 차례로 `apply` 합니다.

### 5. Workload seed 값 입력

provider Vault는 여전히 workload seed source of truth 이므로, app 비밀값은 한 번 입력해야 합니다.

```bash
export VAULT_ADDR=http://127.0.0.1:18200
export VAULT_TOKEN="$(vault write -field=token auth/approle/login \
  role_id="<vault-transit-workflow-role-id>" \
  secret_id="<vault-transit-workflow-secret-id>")"

./scripts/vault-transit/dev/populate-workload-seeds.sh
```

이 스크립트는 값을 **프롬프트로 입력받기 때문에 shell history에 실제 secret이 남지 않습니다.**

주의:

- 이 스크립트는 `TF_VAR_transit_vault_token` 이 아니라 **`VAULT_TOKEN`** 을 사용합니다.
- `VAULT_ADDR` 는 provider Vault 포트포워드인 `http://127.0.0.1:18200` 이어야 합니다.

`populate-workload-seeds.example.sh` 는 필요한 key 구조를 보여주는 참고용 예시입니다.

입력 경로는 목적 기준으로 나뉩니다.

- `kv/dev/workload/platform/postgres/superuser`
- `kv/dev/workload/platform/postgres/auth-server`
- `kv/dev/workload/platform/postgres/keycloak`
- `kv/dev/workload/platform/keycloak/bootstrap-admin`
- `kv/dev/workload/platform/keycloak/client-auth-server`

`kv/dev/workload/bootstrap` 의 workload AppRole credential 은 이제 `terraform/vault/dev` 가 자동으로 씁니다. 사람이 따로 넣지 않습니다.

### 6. 운영자 토큰이 필요한 경우

장기 토큰을 Terraform state 에 저장하지 않기 위해 `vault-transit-admin-dev` 토큰은 자동 발급하지 않습니다.
직접 점검이 필요하면 privileged token 으로 아래처럼 짧은 토큰을 발급합니다.

```bash
export VAULT_ADDR=http://127.0.0.1:18200
export VAULT_TOKEN="$TF_VAR_vault_token"

vault token create -orphan -policy=vault-transit-admin-dev -ttl=1h
```

### 주의

- `terraform/vault-transit/dev` 의 local state 는 [`.terraform-state/vault-transit-dev.tfstate`](/home/donghyeon/dev/Project-Auth-GitOps/.terraform-state/vault-transit-dev.tfstate) 에 저장됩니다.
- Vault provider state 에는 민감한 값이 들어가므로 self-hosted runner 와 로컬 작업 디렉터리를 동일하게 보호해야 합니다.
