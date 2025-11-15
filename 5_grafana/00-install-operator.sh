#!/bin/bash
set -e

echo "Installing Grafana Operator using Helm..."

# Add Grafana Helm repository (OCI registry)
# Official Helm Chart: oci://ghcr.io/grafana/helm-charts/grafana-operator
# Source: https://github.com/grafana/grafana-operator

# Create namespace for Grafana
kubectl create namespace grafana-system --dry-run=client -o yaml | kubectl apply -f -

# Install Grafana Operator using official Helm chart
helm upgrade --install grafana-operator \
  oci://ghcr.io/grafana/helm-charts/grafana-operator \
  --version v5.20.0 \
  --namespace grafana-system \
  --wait \
  --timeout 10m

echo "Grafana Operator installed successfully!"
echo "Verifying installation..."

# Wait for the operator to be ready
kubectl wait --for=condition=available --timeout=300s \
  deployment/grafana-operator \
  -n grafana-system

echo "Grafana Operator is ready!"
