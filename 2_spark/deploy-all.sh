#!/bin/bash

# Apache Spark Stack Deployment Script
# This script deploys the complete Spark environment on K3s

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================="
echo "Deploying Apache Spark Stack"
echo "=========================================="
echo ""

# Step 1: Install Spark Kubernetes Operator
echo "Step 1: Installing Spark Kubernetes Operator..."
bash "$SCRIPT_DIR/00-install-operator.sh"
echo ""

# Wait for operator to be ready
echo "Waiting for Spark Operator to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=spark-kubernetes-operator -n spark-operator --timeout=300s
echo ""

# Step 2: Create necessary directories on host
echo "Step 2: Creating necessary directories for Spark..."
DIRS=(
    "/mnt/nvme/spark-tmp"
    "/mnt/nvme/spark-warehouse"
    "/mnt/nvme/spark-events"
    "/mnt/nvme/spark-output"
    "/mnt/hdd/spark-output"
    "/mnt/gcs/spark-output"
)

for dir in "${DIRS[@]}"; do
    if [ ! -d "$dir" ]; then
        echo "Creating directory: $dir"
        sudo mkdir -p "$dir"
        sudo chmod 777 "$dir"
    else
        echo "Directory already exists: $dir"
    fi
done
echo ""

# Step 3: Deploy Spark Cluster (Optional)
echo "Step 3: Deploying Spark Cluster..."
echo "Do you want to deploy a standalone Spark cluster? (y/n)"
read -r deploy_cluster

if [ "$deploy_cluster" = "y" ] || [ "$deploy_cluster" = "Y" ]; then
    kubectl apply -f "$SCRIPT_DIR/02-spark-cluster.yaml"
    echo "Spark Cluster deployed. Waiting for it to be ready..."
    sleep 10
    kubectl get sparkcluster
else
    echo "Skipping Spark Cluster deployment."
fi
echo ""

# Step 4: Test with Spark Pi example
echo "Step 4: Testing with Spark Pi example..."
echo "Do you want to run the Spark Pi test? (y/n)"
read -r run_test

if [ "$run_test" = "y" ] || [ "$run_test" = "Y" ]; then
    kubectl apply -f "$SCRIPT_DIR/01-spark-pi-example.yaml"
    echo "Spark Pi example submitted. Monitor with:"
    echo "  kubectl get sparkapp spark-pi-example -w"
    echo "  kubectl logs -f spark-pi-example-driver"
else
    echo "Skipping Spark Pi test."
fi
echo ""

echo "=========================================="
echo "Spark Stack Deployment Complete"
echo "=========================================="
echo ""
echo "Next Steps:"
echo ""
echo "1. Check Spark Operator status:"
echo "   kubectl get pods -n spark-operator"
echo ""
echo "2. Check Spark applications:"
echo "   kubectl get sparkapp"
echo ""
echo "3. Check Spark clusters:"
echo "   kubectl get sparkcluster"
echo ""
echo "4. Deploy data preprocessing job:"
echo "   kubectl apply -f $SCRIPT_DIR/03-data-preprocessing-app.yaml"
echo ""
echo "5. View application logs:"
echo "   kubectl logs -f <pod-name>"
echo ""
echo "6. Cleanup:"
echo "   kubectl delete sparkapp --all"
echo "   kubectl delete sparkcluster --all"
echo "   helm uninstall spark-operator -n spark-operator"
echo ""
