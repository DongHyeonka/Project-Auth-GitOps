# Agent Guide

이 파일은 이 저장소에서 작업을 시작하는 사람과 에이전트를 위한 첫 진입 문서입니다.

## Read First

작업을 시작하면 아래 순서로 문서를 읽습니다.

1. 이 파일 `AGENT.md`
2. 루트 [README.md](/home/donghyeon/dev/Project-Auth-GitOps/README.md)
3. 현재 작업과 직접 관련된 runbook
   - Vault transit: [runbooks/vault-transit/dev/README.md](/home/donghyeon/dev/Project-Auth-GitOps/runbooks/vault-transit/dev/README.md)
   - Workload Vault: [runbooks/vault/dev/README.md](/home/donghyeon/dev/Project-Auth-GitOps/runbooks/vault/dev/README.md)
   - Argo CD 구조: [argocd/README.md](/home/donghyeon/dev/Project-Auth-GitOps/argocd/README.md)

## Working Rules

- README 최상단 `현재 최신 Dev 아키텍처` 는 최신 상태로 유지합니다.
- 기존 cycle은 지우지 말고 README 맨 아래에 새 cycle을 추가합니다.
- ops 변경이나 장애 대응을 했으면 명령, 관찰, 판단 근거, 수정, 검증을 함께 남깁니다.
- 민감한 값은 절대 문서에 기록하지 않습니다.
  - token, password, kubeconfig 본문, secret payload 금지
  - 대신 존재 여부, 길이, secret name, 리소스 상태만 기록
- repo 밖 임시 파일(`/tmp/...`)로 작업한 secret manifest는 Git에 넣지 않습니다.

## Troubleshooting Format

README cycle의 `### 6. 트러블슈팅 메모` 에 아래 형식으로 남깁니다.

- 재현/확인 명령: 실제로 사용한 명령
- 핵심 관찰값: 에러 문구, 상태 변화, 이벤트, 로그 핵심
- 판단 근거: 왜 그 관찰값을 보고 해당 원인이라고 판단했는지
- 수정 또는 조치: 어떤 파일/리소스를 바꿨는지
- 검증 명령: 해결 여부를 다시 확인한 명령

## Current Dev Pitfalls

- Argo CD `Application` 이 `Repository not found` 를 내면 로컬 git 인증이 아니라 `argocd` namespace의 repo credential secret부터 확인합니다.
- self-hosted runner 문제는 workflow YAML보다 먼저 runner 호스트의 실제 CLI 설치 여부를 확인합니다.
  - `command -v kubectl vault jq base64 curl terraform`
- Vault raft 사용 시 `api_addr`, `cluster_addr`, listener `cluster_address`, service/deployment의 `8201` 포트 일관성을 먼저 확인합니다.
- `hashicorp/vault` 이미지를 ConfigMap mount와 함께 쓸 때는 read-only mount 충돌과 단일 PVC rollout 충돌을 같이 봅니다.
  - 필요하면 `/tmp` 로 config 복사 후 실행, `strategy: Recreate` 적용
- Vault Agent template에 여러 `export` 줄을 렌더링할 때는 aggressive trim(`{{- ... -}}`) 때문에 줄바꿈이 붙지 않는지 실제 `/vault/secrets/*` 파일을 확인합니다.
- Postgres PVC를 유지하는 상태에서 Vault KV만 바꾸면 DB 내부 사용자 비밀번호와 주입값이 어긋날 수 있습니다. KV 값과 persisted DB state를 함께 확인합니다.
- Headless Service를 DB connection host로 쓸 때는 pod 안에서 실제로 어떤 이름이 해석되는지 먼저 확인합니다.
  - `postgres.platform.svc.cluster.local` 이 안 되면 `postgres-0.postgres.platform.svc.cluster.local` 같이 pod FQDN 확인
- CI에서 Terraform local backend를 쓰면 self-hosted runner가 기존 `.terraform-state/*.tfstate` 를 실제로 보고 있는지 먼저 확인합니다. state가 완전히 없을 때뿐 아니라 일부 리소스만 남은 partial state도 위험합니다.
  - `terraform state list`
  - `terraform state show <resource>`
  - workflow에서 빠진 리소스를 개별 import 하도록 유지
  - 단, `vault_approle_auth_backend_role_secret_id` 처럼 provider가 import를 지원하지 않는 리소스는 예외로 두고 재생성으로 수렴시킵니다.
- `kubectl rollout status` 실패 시 `describe`, `logs`, `events` 를 세트로 봅니다.

## Default Command Order

Argo CD app 문제:

```bash
kubectl -n argocd get applications
kubectl -n argocd describe application <name>
kubectl -n argocd get secrets
```

Runner 문제:

```bash
command -v kubectl
command -v vault
command -v terraform
```

Vault pod 문제:

```bash
kubectl -n <ns> get deploy,pods
kubectl -n <ns> describe deployment <name>
kubectl -n <ns> logs deploy/<name> --tail=200
kubectl -n <ns> get events --sort-by=.lastTimestamp | tail -n 30
```
