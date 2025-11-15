#!/bin/bash

# Apache Spark Kubernetes Operator Installation Script
# Official Helm Chart: https://apache.github.io/spark-kubernetes-operator/
# Artifact Hub: https://artifacthub.io/packages/helm/spark-kubernetes-operator/spark-kubernetes-operator/

set -e

echo "=========================================="
echo "Installing Apache Spark Kubernetes Operator"
echo "=========================================="

# Add Spark Kubernetes Operator Helm repository
echo "Adding Spark Helm repository..."
helm repo add spark https://apache.github.io/spark-kubernetes-operator

# Update Helm repositories
echo "Updating Helm repositories..."
helm repo update

# Create namespace for Spark
NAMESPACE="spark-operator"
echo "Creating namespace: $NAMESPACE"
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Install Spark Kubernetes Operator
echo "Installing Spark Kubernetes Operator..."
helm install spark-operator spark/spark-kubernetes-operator \
  --namespace $NAMESPACE \
  --create-namespace \
  --wait

echo ""
echo "=========================================="
echo "Spark Kubernetes Operator Installation Complete"
echo "=========================================="
echo ""
echo "Verify installation:"
echo "  kubectl get pods -n $NAMESPACE"
echo "  kubectl get crd | grep spark"
echo ""
