#!/bin/bash
# JupyterHub 설치 스크립트

# Jupyter Config 적용
kubectl apply -f 02-jupyter-config.yaml

# Helm Repository 추가
helm repo add jupyterhub https://hub.jupyter.org/helm-chart/
helm repo update

# Secret Token 생성
SECRET_TOKEN=$(openssl rand -hex 32)

# JupyterHub 설치
helm install jupyterhub jupyterhub/jupyterhub \
  --namespace jupyterhub \
  --create-namespace \
  --values 01-jupyterhub-values.yaml \
  --set proxy.secretToken=$SECRET_TOKEN \
  --wait

# 설치 확인
kubectl get pods -n jupyterhub
kubectl get svc -n jupyterhub
kubectl get ingress -n jupyterhub

echo "JupyterHub 설치 완료!"
echo "JupyterHub URL: https://jupyter.mireu.xyz"
echo ""
echo "중요: Google OAuth 설정이 필요합니다."
echo "1. Google Cloud Console에서 OAuth 2.0 클라이언트 ID 생성"
echo "2. 승인된 리디렉션 URI: https://jupyter.mireu.xyz/hub/oauth_callback"
echo "3. 01-jupyterhub-values.yaml에 client_id와 client_secret 입력 후 재배포"
