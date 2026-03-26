## Dev Public TLS

이 문서는 dev public ingress TLS에서 사용하는 **로컬 사설 CA** 를 운영자 노트북 trust store에 등록하는 절차를 정리합니다.

현재 dev public host는 아래 3개입니다.

- `auth-public.auth-dev.svc.cluster.local`
- `api-public.api-dev.svc.cluster.local`
- `keycloak-public.platform.svc.cluster.local`

브라우저/CLI가 TLS 경고 없이 이 호스트들에 접근하려면 repo에 저장된 CA 인증서를 로컬 trust store에 1회 등록해야 합니다.

### 1. CA 파일 내보내기

```bash
./scripts/public-tls/dev/export-ca.sh
```

기본 출력 경로는 `.local/project-auth-dev-public-ca.crt` 입니다.

원하는 경로를 직접 넘길 수도 있습니다.

```bash
./scripts/public-tls/dev/export-ca.sh /tmp/project-auth-dev-public-ca.crt
```

### 2. Linux trust store 등록

Ubuntu/Debian 계열은 아래 스크립트를 사용합니다.

```bash
sudo ./scripts/public-tls/dev/install-linux-ca.sh
```

직접 하고 싶으면 아래와 같습니다.

```bash
sudo install -D -m 0644 \
  runbooks/public-tls/dev/project-auth-dev-public-ca.crt \
  /usr/local/share/ca-certificates/project-auth-dev-public-ca.crt
sudo update-ca-certificates
```

### 3. macOS trust store 등록

```bash
sudo ./scripts/public-tls/dev/install-macos-ca.sh
```

직접 실행하면 아래와 같습니다.

```bash
sudo security add-trusted-cert \
  -d \
  -r trustRoot \
  -k /Library/Keychains/System.keychain \
  runbooks/public-tls/dev/project-auth-dev-public-ca.crt
```

### 4. hosts 매핑

로컬 DNS가 없으면 public host를 Traefik 진입 IP에 매핑해야 합니다.

```text
<TRAEFIK_LB_IP> auth-public.auth-dev.svc.cluster.local api-public.api-dev.svc.cluster.local keycloak-public.platform.svc.cluster.local
```

### 5. 확인

```bash
curl -I https://auth-public.auth-dev.svc.cluster.local
curl -I https://keycloak-public.platform.svc.cluster.local/realms/project-auth/.well-known/openid-configuration
```

CLI는 trust store 등록 후 별도 `-k` 없이 동작해야 합니다.
