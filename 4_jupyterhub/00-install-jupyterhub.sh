#!/bin/bash
set -e

echo "================================================"
echo "Installing JupyterHub using Official Helm Chart"
echo "================================================"
echo ""

# Add JupyterHub Helm repository
echo "[1/4] Adding JupyterHub Helm repository..."
helm repo add jupyterhub https://hub.jupyter.org/helm-chart/
helm repo update

echo ""
echo "[2/4] Creating namespace for JupyterHub..."
kubectl create namespace jupyterhub --dry-run=client -o yaml | kubectl apply -f -

echo ""
echo "[3/4] Installing NVIDIA Device Plugin for GPU support..."
kubectl create namespace gpu-operator --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/v0.14.3/nvidia-device-plugin.yml

echo ""
echo "[4/4] Installing JupyterHub Helm Chart..."
echo "Chart URL: https://github.com/jupyterhub/zero-to-jupyterhub-k8s"
echo ""

helm upgrade --install jupyterhub jupyterhub/jupyterhub \
  --namespace jupyterhub \
  --version 3.2.1 \
  --values 4_jupyterhub/values.yaml \
  --timeout 10m

echo ""
echo "================================================"
echo "JupyterHub Installation Complete!"
echo "================================================"
echo ""
echo "Next steps:"
echo "1. Build and push custom Docker image:"
echo "   docker build -t your-registry/jupyterhub-cuda-jax:latest ."
echo "   docker push your-registry/jupyterhub-cuda-jax:latest"
echo ""
echo "2. Update values.yaml with your Google OAuth credentials"
echo ""
echo "3. Check deployment status:"
echo "   kubectl get pods -n jupyterhub"
echo ""
echo "4. Access JupyterHub:"
echo "   kubectl get svc -n jupyterhub"
echo "   Access via NodePort 30080 (HTTP) or 30443 (HTTPS)"
echo ""
