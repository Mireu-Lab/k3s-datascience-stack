#!/bin/bash

echo "--- Starting Cleanup Process ---"

# 1. Uninstall JupyterHub
echo "Uninstalling JupyterHub..."
helm uninstall jupyterhub -n jupyterhub
kubectl delete secret google-oauth-secret -n jupyterhub --ignore-not-found=true
kubectl delete namespace jupyterhub --ignore-not-found=true

# 2. Uninstall Monitoring Stack
echo "Uninstalling Monitoring Stack (Prometheus & Grafana)..."
helm uninstall prometheus -n monitoring
kubectl delete namespace monitoring --ignore-not-found=true

# 3. Uninstall Spark Operator
echo "Uninstalling Spark Operator..."
helm uninstall spark-operator -n spark-operator
kubectl delete namespace spark-operator --ignore-not-found=true

# 4. Uninstall Hadoop (HDFS)
echo "Deleting HDFS Cluster and uninstalling HDFS Operator..."
kubectl delete hdfscluster hdfs-cluster -n default --ignore-not-found=true
helm uninstall hdfs-operator -n stackable
kubectl delete namespace stackable --ignore-not-found=true

# 5. Uninstall PostgreSQL
echo "Deleting PostgreSQL Cluster and uninstalling CloudNativePG Operator..."
kubectl delete cluster postgres-db -n default --ignore-not-found=true
kubectl delete secret postgres-superuser-secret -n default --ignore-not-found=true
helm uninstall cnpg -n cnpg-system
kubectl delete namespace cnpg-system --ignore-not-found=true

# 6. Uninstall Prerequisites
echo "Uninstalling Prerequisites (cert-manager & NVIDIA plugin)..."
helm uninstall cert-manager -n cert-manager
kubectl delete clusterissuer letsencrypt-production --ignore-not-found=true
kubectl delete namespace cert-manager --ignore-not-found=true

helm uninstall nvidia-device-plugin -n nvidia-device-plugin
kubectl delete namespace nvidia-device-plugin --ignore-not-found=true

# 7. Delete Storage configurations
echo "Deleting Storage configurations (PVs and StorageClasses)..."
kubectl delete -f storage/storage-pv.yaml --ignore-not-found=true
kubectl delete -f storage/storage-class.yaml --ignore-not-found=true

# 8. Final check for any remaining resources (optional)
# Note: Be cautious with these commands in a shared cluster
kubectl delete pvc --all -n default
kubectl delete configmap --all -n default

echo "--- Cleanup Process Finished ---"
echo "Note: Some resources, especially namespaces, might take a few moments to be completely terminated."
