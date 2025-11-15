#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Starting PostgreSQL deployment..."

# Install CloudNativePG Operator
echo "Step 1: Installing CloudNativePG Operator..."
bash "${SCRIPT_DIR}/00-install-operator.sh"

echo "Waiting 10 seconds for operator to stabilize..."
sleep 10

# Create backup credentials secret (optional - modify with real credentials if needed)
echo "Step 2: Creating backup credentials secret..."
kubectl apply -f "${SCRIPT_DIR}/03-backup-secret.yaml"

# Deploy PostgreSQL Cluster
echo "Step 3: Deploying PostgreSQL Cluster..."
kubectl apply -f "${SCRIPT_DIR}/01-postgres-cluster.yaml"

echo "Waiting for PostgreSQL cluster to be ready..."
kubectl wait --for=condition=Ready cluster/postgres-cluster -n default --timeout=600s || true

# Deploy Pooler
echo "Step 4: Deploying PgBouncer Pooler..."
kubectl apply -f "${SCRIPT_DIR}/02-pooler.yaml"

# Deploy Scheduled Backup
echo "Step 5: Setting up scheduled backups..."
kubectl apply -f "${SCRIPT_DIR}/04-scheduledbackup.yaml"

# Deploy pgAdmin
echo "Step 6: Deploying pgAdmin..."
kubectl apply -f "${SCRIPT_DIR}/06-pgadmin.yaml"

echo "Waiting for pgAdmin to be ready..."
kubectl wait --for=condition=Ready pod -l app=pgadmin -n default --timeout=300s || true

echo ""
echo "PostgreSQL deployment completed!"
echo ""
echo "To get the PostgreSQL superuser password, run:"
echo "kubectl get secret postgres-cluster-superuser -n default -o jsonpath='{.data.password}' | base64 -d"
echo ""
echo "To connect to PostgreSQL:"
echo "kubectl exec -it postgres-cluster-1 -n default -- psql -U postgres"
echo ""
echo "Connection via pooler service:"
echo "Service: postgres-pooler-rw.default.svc.cluster.local:5432"
echo ""
echo "pgAdmin Web UI (after Traefik setup):"
echo "URL: https://pg.mireu.xyz"
echo "Email: admin@mireu.xyz"
echo "Password: admin123!@#"
echo ""
