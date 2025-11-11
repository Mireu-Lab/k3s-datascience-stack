#!/bin/bash

# Add the Spark Operator Helm repository
helm repo add spark-operator https://googlecloudplatform.github.io/spark-on-k8s-operator

# Update Helm repositories
helm repo update

# Uninstall existing Spark operator if it exists
helm uninstall spark-operator --namespace spark-operator

# Install the Spark operator
helm install spark-operator spark-operator/spark-operator --namespace spark-operator --create-namespace --set sparkJobNamespace=default

echo "Spark operator installed."
echo "Waiting for operator to be ready..."
kubectl wait --for=condition=Available=True deployment/spark-operator -n spark-operator --timeout=300s

echo "Spark operator is ready."
