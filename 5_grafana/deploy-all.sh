#!/bin/bash
set -e

echo "================================"
echo "Deploying Grafana Stack"
echo "================================"

# Step 1: Install Grafana Operator
echo ""
echo "Step 1/4: Installing Grafana Operator..."
bash 5_grafana/00-install-operator.sh

# Wait for operator to be fully ready
echo "Waiting for operator to stabilize..."
sleep 10

# Step 2: Deploy Grafana Instance
echo ""
echo "Step 2/4: Deploying Grafana Instance..."
kubectl apply -f 5_grafana/01-grafana-instance.yaml

# Wait for Grafana to be ready
echo "Waiting for Grafana instance to be ready..."
kubectl wait --for=condition=ready pod -l app=grafana -n grafana --timeout=300s || true

# Step 3: Configure DataSources
echo ""
echo "Step 3/4: Configuring DataSources..."
kubectl apply -f 5_grafana/02-datasources.yaml

# Step 4: Deploy Dashboards
echo ""
echo "Step 4/4: Deploying Dashboards..."
kubectl apply -f 5_grafana/03-dashboards.yaml

echo ""
echo "================================"
echo "Grafana Stack Deployment Complete!"
echo "================================"
echo ""
echo "Access Information:"
echo "  - Grafana URL: http://<node-ip>:30300"
echo "  - Default Username: admin"
echo "  - Default Password: admin123"
echo ""
echo "Verify deployment:"
echo "  kubectl get grafana -n grafana"
echo "  kubectl get grafanadatasource -n grafana"
echo "  kubectl get grafanadashboard -n grafana"
echo ""
echo "View Grafana logs:"
echo "  kubectl logs -n grafana -l app=grafana"
echo ""
