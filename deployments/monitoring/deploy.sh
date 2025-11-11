#!/bin/bash

# Add Prometheus Community Helm repository
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Uninstall existing release
helm uninstall prometheus -n monitoring

# Create namespace
kubectl create namespace monitoring

# Install kube-prometheus-stack
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  -f deployments/monitoring/grafana-values.yaml

echo "Prometheus and Grafana stack deployment initiated."
echo "It may take a few minutes for all pods to be ready."
echo "Grafana will be available at https://grafana.mireu.xyz"
echo "Default credentials (user/password): admin/prom-operator"
echo "You should change the password on first login."
