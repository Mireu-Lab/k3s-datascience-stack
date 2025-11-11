#!/bin/bash

# This script deploys the entire data science stack in the correct order.
# Ensure you have configured the necessary values in the YAML files,
# especially in deployments/jupyterhub/values.yaml and deployments/jupyterhub/deploy.sh.

set -e # Exit immediately if a command exits with a non-zero status.

BASE_DIR=$(dirname "$0")

echo "--- Starting Full Deployment Process ---"

# 1. Setup Storage
echo "Step 1: Setting up storage (PVs and StorageClasses)..."
bash "${BASE_DIR}/storage/setup.sh"
echo "Storage setup complete."
sleep 5

# 2. Install Prerequisites
echo "Step 2: Installing prerequisites (NVIDIA Plugin, Cert-Manager)..."
bash "${BASE_DIR}/prerequisites/deploy.sh"
echo "Prerequisites installation complete. Waiting for cert-manager webhook to be ready..."
kubectl wait --for=condition=Available=True deployment/cert-manager-webhook -n cert-manager --timeout=300s
echo "Cert-manager is ready."
sleep 5

# 3. Deploy Data Frameworks
echo "Step 3.1: Deploying PostgreSQL..."
bash "${BASE_DIR}/postgresql/deploy.sh"
echo "PostgreSQL deployment initiated."
sleep 5

echo "Step 3.2: Deploying Hadoop (HDFS)..."
bash "${BASE_DIR}/hadoop/deploy.sh"
echo "Hadoop (HDFS) deployment initiated."
sleep 5

echo "Step 3.3: Deploying Spark Operator..."
bash "${BASE_DIR}/spark/deploy.sh"
echo "Spark Operator deployment initiated."
sleep 5

# 4. Deploy Monitoring Stack
echo "Step 4: Deploying Monitoring Stack (Prometheus & Grafana)..."
bash "${BASE_DIR}/monitoring/deploy.sh"
echo "Monitoring stack deployment initiated."
sleep 5

# 5. Deploy JupyterHub
echo "Step 5: Deploying JupyterHub..."
echo "IMPORTANT: Please ensure you have replaced the placeholder values in"
echo "           deployments/jupyterhub/deploy.sh (Google OAuth Secret)"
echo "           deployments/jupyterhub/values.yaml (secretToken, email, etc.)"
read -p "Press [Enter] to continue with JupyterHub deployment..."

bash "${BASE_DIR}/jupyterhub/deploy.sh"
echo "JupyterHub deployment initiated."

echo "--- Full Deployment Process Finished ---"
echo "It may take several minutes for all pods across all namespaces to become ready."
echo "You can monitor the status with 'kubectl get pods --all-namespaces -w'"
