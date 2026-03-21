## Argo CD Structure

`argocd/` 디렉터리는 환경(`dev`, `prod`)과 성격(`apps`, `infra`) 기준으로 나눠 관리합니다.

- `applications/<env>/apps`: 서비스 애플리케이션 선언
- `applications/<env>/infra`: 공용 인프라/컨트롤러 선언
- `projects/<env>/apps-project.yaml`: 서비스 애플리케이션용 AppProject
- `projects/<env>/infra-project.yaml`: 공용 인프라용 AppProject

현재 `dev`에는 실제 선언을 두고, `prod`는 이후 운영 확장을 위한 구조와 프로젝트 골격을 먼저 유지합니다.
