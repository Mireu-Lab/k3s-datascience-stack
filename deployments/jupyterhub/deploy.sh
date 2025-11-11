#!/bin/bash

# Add JupyterHub Helm repository
helm repo add jupyterhub https://jupyterhub.github.io/helm-chart/
helm repo update

# Uninstall existing JupyterHub release
helm uninstall jupyterhub -n jupyterhub

# Create namespace
kubectl create namespace jupyterhub

# Create a secret for Google OAuth credentials
# IMPORTANT: Replace YOUR_CLIENT_ID, YOUR_CLIENT_SECRET, and YOUR_OAUTH_CALLBACK_URL
kubectl create secret generic google-oauth-secret -n jupyterhub \
  --from-literal=clientId='YOUR_CLIENT_ID' \
  --from-literal=clientSecret='YOUR_CLIENT_SECRET' \
  --from-literal=oauthCallbackUrl='https://jupyter.mireu.xyz/hub/oauth_callback'

# Install JupyterHub
helm install jupyterhub jupyterhub/jupyterhub \
  --namespace jupyterhub \
  -f deployments/jupyterhub/values.yaml

echo "JupyterHub deployment initiated."
echo "It may take a few minutes for all pods to be ready."
echo "Check status with: kubectl get pod -n jupyterhub"
