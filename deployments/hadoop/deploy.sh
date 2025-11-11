#!/bin/bash

# Add the Stackable Helm repository
helm repo add stackable https://repo.stackable.tech/repository/helm-stable/
helm repo update

# Uninstall existing HDFS operator if it exists
helm uninstall hdfs-operator -n hdfs-operator

# Install the HDFS operator
helm install hdfs-operator stackable/hdfs-operator -n hdfs-operator --create-namespace

echo "HDFS operator installed."
echo "Waiting for operator to be ready..."
kubectl wait --for=condition=Available=True deployment/hdfs-operator -n hdfs-operator --timeout=300s

echo "Operator is ready. Applying HDFS cluster configuration..."

# Apply the HDFS cluster configuration
kubectl apply -f deployments/hadoop/hdfs-cluster.yaml

echo "HDFS cluster deployment initiated."
