#!/bin/bash
# Traefik Ingress Controller 설치 스크립트

# TLS Secret 배포
kubectl apply -f 02-tls-secret.yaml

# Helm Repository 추가
helm repo add traefik https://traefik.github.io/charts
helm repo update

# Traefik 설치
helm install traefik traefik/traefik \
  --namespace traefik \
  --create-namespace \
  --values 01-traefik-values.yaml \
  --wait

# Traefik Dashboard Ingress 배포
kubectl apply -f 03-traefik-dashboard-ingress.yaml

# 설치 확인
kubectl get pods -n traefik
kubectl get svc -n traefik
kubectl get secrets -n traefik
kubectl get ingressroute -n traefik

echo "Traefik Ingress Controller 설치 완료!"
echo "다음 도메인이 라우팅됩니다:"
echo "  - https://traefik.mireu.xyz (Traefik Dashboard)"
echo "  - https://jupyter.mireu.xyz"
echo "  - https://grafana.mireu.xyz"
echo "  - https://spark.mireu.xyz"
echo "  - https://hdfs.mireu.xyz"
echo "  - https://yarn.mireu.xyz"
echo "  - https://pg.mireu.xyz"
echo "  - https://keycloak.mireu.xyz"
