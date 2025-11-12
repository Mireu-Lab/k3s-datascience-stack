#!/bin/bash

# Add JupyterHub Helm repository
helm repo add jupyterhub https://jupyterhub.github.io/helm-chart/
helm repo update

# Uninstall existing JupyterHub release to ensure a clean slate
helm uninstall jupyterhub -n jupyterhub --ignore-not-found=true

# Create namespace if it doesn't exist
kubectl create namespace jupyterhub --dry-run=client -o yaml | kubectl apply -f -

# Recreate the secret for Google OAuth credentials to ensure it's up-to-date
kubectl delete secret google-oauth-secret -n jupyterhub --ignore-not-found=true
kubectl create secret generic google-oauth-secret -n jupyterhub \
  --from-literal=clientId='YOUR_CLIENT_ID' \
  --from-literal=clientSecret='YOUR_CLIENT_SECRET' \
  --from-literal=oauthCallbackUrl='https://jupyter.mireu.xyz/hub/oauth_callback'

# Install JupyterHub
helm install jupyterhub jupyterhub/jupyterhub \
  --namespace jupyterhub \
  -f deployments/jupyterhub/values.yaml

# Apply RBAC for Spark (idempotent)
kubectl apply -f deployments/jupyterhub/rbac-spark.yaml

echo "JupyterHub deployment initiated."
echo "It may take a few minutes for all pods to be ready."
echo "Check status with: sudo kubectl get pod -n jupyterhub"
