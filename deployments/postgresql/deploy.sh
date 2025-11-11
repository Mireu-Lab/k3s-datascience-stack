#!/bin/bash

# Add CloudNativePG Helm repository
helm repo add cnpg https://cloudnative-pg.github.io/charts

# Update Helm repositories
helm repo update

# Uninstall existing release if it exists
helm uninstall cnpg --namespace cnpg-system

# Install the CloudNativePG operator
helm install cnpg cnpg/cloudnative-pg \
  --namespace cnpg-system \
  --create-namespace

echo "CloudNativePG operator installed."
echo "Waiting for operator to be ready..."
kubectl wait --for=condition=Available=True deployment/cnpg-controller-manager -n cnpg-system --timeout=300s

echo "Operator is ready. Applying PostgreSQL cluster configuration..."

# Apply the cluster configuration
kubectl apply -f deployments/postgresql/cluster.yaml

echo "PostgreSQL cluster deployment initiated."
