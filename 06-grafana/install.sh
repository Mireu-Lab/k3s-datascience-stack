#!/bin/bash
# Grafana 및 Prometheus 설치 스크립트

# Prometheus 배포
kubectl apply -f 03-prometheus.yaml

# Grafana Dashboards ConfigMap 적용
kubectl apply -f 02-grafana-dashboards.yaml

# Grafana 설치
helm install grafana oci://registry-1.docker.io/bitnamicharts/grafana \
  --namespace monitoring \
  --create-namespace \
  --values 01-grafana-values.yaml \
  --wait

# 설치 확인
kubectl get pods -n monitoring
kubectl get svc -n monitoring
kubectl get ingress -n monitoring

echo "Grafana 및 Prometheus 설치 완료!"
echo "Grafana URL: https://grafana.mireu.xyz"
echo "관리자 계정: admin / GrafanaAdmin123!"
echo ""
echo "Prometheus URL: http://prometheus-server.monitoring.svc.cluster.local:9090"
