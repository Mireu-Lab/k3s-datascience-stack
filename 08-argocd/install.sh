#!/bin/bash
# ArgoCD 설치 스크립트

# SSL/TLS 인증서를 Base64로 인코딩
echo "SSL/TLS 인증서 인코딩 중..."
CERT_BASE64=$(cat ../SSL/mireu.xyz.pem | base64 -w 0)
KEY_BASE64=$(cat ../SSL/mireu.xyz.key | base64 -w 0)

# TLS Secret 파일 업데이트
sed -i "s|BASE64_ENCODED_CERT|${CERT_BASE64}|g" 02-argocd-applications.yaml
sed -i "s|BASE64_ENCODED_KEY|${KEY_BASE64}|g" 02-argocd-applications.yaml

# ArgoCD 설치
helm install argocd oci://registry-1.docker.io/bitnamicharts/argo-cd \
  --namespace argocd \
  --create-namespace \
  --values 01-argocd-values.yaml \
  --wait

# ArgoCD Applications 배포
kubectl apply -f 02-argocd-applications.yaml

# k3s 자동 업그레이드 CronJob 배포
kubectl apply -f 03-k3s-upgrade.yaml

# 설치 확인
kubectl get pods -n argocd
kubectl get svc -n argocd
kubectl get ingress -n argocd
kubectl get applications -n argocd

# 초기 관리자 비밀번호 출력
echo ""
echo "ArgoCD 설치 완료!"
echo "ArgoCD URL: https://argocd.mireu.xyz"
echo "관리자 계정: admin"
echo "초기 비밀번호 확인: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
echo ""
echo "k3s 자동 업그레이드가 매주 일요일 오전 3시에 실행됩니다."
