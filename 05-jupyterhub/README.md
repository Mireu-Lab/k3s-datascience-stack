# JupyterHub 설치 및 구성

## 공식 Helm Chart
- URL: https://github.com/jupyterhub/zero-to-jupyterhub-k8s
- Helm Repo: https://hub.jupyter.org/helm-chart/
- Bitnami Alternative: https://github.com/bitnami/charts/tree/main/bitnami/jupyterhub

## 설치 명령어
```bash
helm repo add jupyterhub https://hub.jupyter.org/helm-chart/
helm repo update

helm install jupyterhub jupyterhub/jupyterhub \
  --namespace jupyterhub \
  --values 01-jupyterhub-values.yaml
```

## 주요 기능
1. Google OAuth 통합 로그인
2. Git Repo URL 기반 자동 워크스페이스 생성 (Login Email + Repo Name)
3. NVIDIA GPU + JAX 사전 설치 컨테이너
4. Hadoop HDFS 자동 마운트
5. Spark 및 PostgreSQL 연결

## WebUI 접근
- JupyterHub: https://jupyter.mireu.xyz
