#!/bin/bash

# 인그레스 설정 스크립트

echo "인그레스 설정 시작..."

# NGINX Ingress Controller 설치
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml

# cert-manager 설치
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.1/cert-manager.yaml

# Let's Encrypt ClusterIssuer 설정
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@mireu.xyz
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - dns01:
        cloudflare:
          email: your-email@mireu.xyz
          apiTokenSecretRef:
            name: cloudflare-api-token-secret
            key: api-token
EOF

# 인그레스 규칙 적용
kubectl apply -f ./k8s/ingress/ingress.yaml

echo "인그레스 설정 완료"