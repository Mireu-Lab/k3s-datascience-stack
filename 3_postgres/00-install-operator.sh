#!/bin/bash
set -e

echo "Installing CloudNativePG Operator..."

# Add CloudNativePG Helm repository
# Official Helm chart: https://github.com/cloudnative-pg/cloudnative-pg
helm repo add cnpg https://cloudnative-pg.github.io/charts
helm repo update

# Create namespace for PostgreSQL operator
kubectl create namespace cnpg-system --dry-run=client -o yaml | kubectl apply -f -

# Install CloudNativePG operator
helm upgrade --install cnpg \
  --namespace cnpg-system \
  cnpg/cloudnative-pg

echo "Waiting for CloudNativePG operator to be ready..."
kubectl wait --for=condition=available --timeout=300s \
  deployment/cnpg-cloudnative-pg \
  -n cnpg-system

echo "CloudNativePG Operator installed successfully!"
