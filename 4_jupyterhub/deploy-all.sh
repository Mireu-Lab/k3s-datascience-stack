#!/bin/bash
set -e

echo "================================================"
echo "Deploying Complete JupyterHub Stack"
echo "================================================"
echo ""

# Step 1: Install JupyterHub
echo "Step 1: Installing JupyterHub..."
bash 4_jupyterhub/00-install-jupyterhub.sh

echo ""
echo "Waiting for JupyterHub pods to be ready..."
kubectl wait --for=condition=ready pod -l app=jupyterhub -n jupyterhub --timeout=300s || true

echo ""
echo "================================================"
echo "Deployment Complete!"
echo "================================================"
echo ""
echo "Important next steps:"
echo ""
echo "1. Container image is built via GitHub Actions:"
echo "   - Workflow: .github/workflows/build-jupyterhub-image.yml"
echo "   - Image: ghcr.io/mireu-lab/jupyterhub-cuda-jax:latest"
echo "   - Trigger: Push Dockerfile changes or manual workflow dispatch"
echo ""
echo "2. Configure Google OAuth:"
echo "   bash 02-setup-oauth.sh"
echo ""
echo "3. Create HDFS PVC (if needed):"
echo "   bash 03-create-hdfs-pvc.sh"
echo ""
echo "4. Check status:"
echo "   kubectl get all -n jupyterhub"
echo ""
echo "5. Get JupyterHub URL:"
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
echo "   http://${NODE_IP}:30080"
echo ""
echo "================================================"
echo ""
