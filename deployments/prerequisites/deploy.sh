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

# Create Cloudflare API token secret (expects CLOUDFLARE_API_TOKEN env var)
if [ -z "$CLOUDFLARE_API_TOKEN" ]; then
  echo "WARNING: CLOUDFLARE_API_TOKEN is not set. Set it to enable DNS-01 validation for wildcard certs." >&2
  echo "Export it and re-run to create the secret automatically, or create the secret manually:" >&2
  echo "kubectl -n cert-manager create secret generic cloudflare-api-token-secret --from-literal=api-token=YOUR_TOKEN" >&2
else
  kubectl -n cert-manager create secret generic cloudflare-api-token-secret \
    --from-literal=api-token="$CLOUDFLARE_API_TOKEN" \
    --dry-run=client -o yaml | kubectl apply -f -
  echo "Cloudflare API token secret applied in cert-manager namespace."
fi

kubectl apply -f deployments/prerequisites/letsencrypt-issuer.yaml

echo "Applying wildcard certificate and Traefik TLSStore (default certificate)..."
kubectl apply -f deployments/prerequisites/wildcard-certificate.yaml
kubectl apply -f deployments/prerequisites/traefik-default-tlsstore.yaml
kubectl apply -f deployments/prerequisites/traefik-https-redirect.yaml

echo "Prerequisites deployment complete."
