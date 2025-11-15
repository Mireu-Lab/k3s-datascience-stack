#!/bin/bash
# ArgoCD 제거 스크립트

echo "ArgoCD 제거 중..."

# k3s 업그레이드 CronJob 제거
kubectl delete -f 03-k3s-upgrade.yaml --ignore-not-found

# ArgoCD Applications 제거
kubectl delete -f 02-argocd-applications.yaml --ignore-not-found

# ArgoCD Helm Release 제거
helm uninstall argocd --namespace argocd || true

# Namespace 제거
kubectl delete namespace argocd --ignore-not-found

echo "ArgoCD 제거 완료!"
