#!/bin/bash
set -e

echo "=========================================="
echo "Installing OAuth2 Proxy via Helm"
echo "=========================================="

# Set kubeconfig for k3s
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

# Namespace
NAMESPACE="oauth2-proxy"

# Add OAuth2 Proxy Helm repository
echo ""
echo "Adding OAuth2 Proxy Helm repository..."
helm repo add oauth2-proxy https://oauth2-proxy.github.io/manifests
helm repo update

# Create namespace
echo ""
echo "Creating namespace ${NAMESPACE}..."
kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

# Install OAuth2 Proxy
echo ""
echo "Installing OAuth2 Proxy..."
helm upgrade --install oauth2-proxy oauth2-proxy/oauth2-proxy \
  --namespace ${NAMESPACE} \
  -f 7_keycloak/oauth2-proxy-values.yaml

echo ""
echo "=========================================="
echo "OAuth2 Proxy installation completed!"
echo "=========================================="
echo ""
echo "Verify installation:"
echo "  kubectl get pods -n ${NAMESPACE}"
echo ""
