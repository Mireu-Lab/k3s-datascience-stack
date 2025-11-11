#!/bin/bash

# 1. Install NVIDIA Device Plugin for GPU support
helm repo add nvdp https://nvidia.github.io/k8s-device-plugin
helm repo update

helm uninstall nvidia-device-plugin -n nvidia-device-plugin
helm install nvidia-device-plugin nvdp/nvidia-device-plugin \
  --namespace nvidia-device-plugin \
  --create-namespace

echo "NVIDIA Device Plugin installed."

# 2. Install cert-manager for automatic TLS certificates
helm repo add jetstack https://charts.jetstack.io
helm repo update

helm uninstall cert-manager -n cert-manager
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.10.0 \
  --set installCRDs=true

echo "Cert-manager installed."
echo "Waiting for cert-manager to be ready..."
kubectl wait --for=condition=Available=True deployment/cert-manager-webhook -n cert-manager --timeout=300s

echo "Cert-manager is ready. Applying ClusterIssuer..."
kubectl apply -f deployments/prerequisites/letsencrypt-issuer.yaml

echo "Prerequisites deployment complete."
