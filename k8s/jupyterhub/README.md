이 디렉토리에는 JupyterHub Helm 차트에 사용할 최소 예시 `values.yaml`이 포함되어 있습니다.

사용 예시:

1) Helm 저장소 추가 및 업데이트

   helm repo add jupyterhub https://jupyterhub.github.io/helm-chart/
   helm repo update

2) values.yaml 파일을 편집하여 client id/secret 및 도메인을 수정

3) 배포

   kubectl create namespace jupyterhub || true
   helm install jhub jupyterhub/jupyterhub --namespace jupyterhub -f values.yaml

참고:
- 실제 운영에서는 HTTPS(ingress controller + cert-manager) 설정과 OAuth 클라이언트 설정, 그리고
  RBAC/네임스페이스 분리 정책을 반드시 구성하세요.
- singleuser 이미지는 `docker/jupyteruser.Dockerfile`을 기반으로 빌드하여 Container Registry에 푸시하세요.
