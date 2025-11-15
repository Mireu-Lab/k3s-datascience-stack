#!/bin/bash
set -e

echo "=========================================="
echo "Installing Keycloak Operator via Official Helm"
echo "Chart: https://artifacthub.io/packages/helm/keycloak-operator/keycloak-operator"
echo "=========================================="

# Set kubeconfig
export KUBECONFIG=/home/limmi/k3s-datascience-stack/k3s.yaml

# Namespace for Keycloak
NAMESPACE="keycloak"

# Add Keycloak Operator Helm repository (Official)
echo ""
echo "Adding Keycloak Operator Helm repository..."
helm repo add keycloak-operator https://kbumsik.io/keycloak-kubernetes/
helm repo update

# Create namespace if it doesn't exist
echo ""
echo "Creating namespace ${NAMESPACE}..."
kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

# Install Keycloak Operator (Official Helm Chart)
echo ""
echo "Installing Keycloak Operator..."
helm upgrade --install keycloak-operator keycloak-operator/keycloak-operator \
  --namespace ${NAMESPACE} \
  --version 0.1.3 \
  --create-namespace \
  --wait

echo ""
echo "Waiting for Keycloak Operator deployment..."
kubectl wait --for=condition=available --timeout=300s deployment/keycloak-operator -n ${NAMESPACE}

echo ""
echo "=========================================="
echo "Keycloak Operator installation complete!"
echo "=========================================="
echo ""
echo "Verify installation:"
echo "  kubectl get pods -n ${NAMESPACE}"
echo "  kubectl get deployment keycloak-operator -n ${NAMESPACE}"
echo ""
echo "Next steps:"
echo "  1. Deploy Keycloak instance: kubectl apply -f 7_keycloak/01-keycloak-instance.yaml"
echo "  2. Configure realm: kubectl apply -f 7_keycloak/02-keycloak-realm.yaml"
echo ""
