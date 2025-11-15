#!/bin/bash
# Grafana 및 Prometheus 제거 스크립트

echo "Grafana 및 Prometheus 제거 중..."

# Prometheus 제거
kubectl delete -f 03-prometheus.yaml --ignore-not-found

# Grafana Dashboards 제거
kubectl delete -f 02-grafana-dashboards.yaml --ignore-not-found

# Grafana Helm Release 제거
helm uninstall grafana --namespace monitoring || true

# Namespace 제거
kubectl delete namespace monitoring --ignore-not-found

echo "Grafana 및 Prometheus 제거 완료!"
