#!/bin/bash
# Traefik Ingress Controller 제거 스크립트

echo "Traefik Ingress Controller 제거 중..."

# Traefik Dashboard Ingress 제거
kubectl delete -f 03-traefik-dashboard-ingress.yaml --ignore-not-found

# Traefik Helm Release 제거
helm uninstall traefik --namespace traefik || true

# TLS Secret 제거
kubectl delete -f 02-tls-secret.yaml --ignore-not-found

# Namespace 제거
kubectl delete namespace traefik --ignore-not-found

echo "Traefik Ingress Controller 제거 완료!"
