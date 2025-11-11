#!/bin/bash

echo "Applying PersistentVolume and StorageClass configurations..."

kubectl apply -f deployments/storage/storage-pv.yaml
kubectl apply -f deployments/storage/storage-class.yaml

echo "Storage setup complete."
