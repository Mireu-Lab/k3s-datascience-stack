#!/bin/bash
set -e

echo "=========================================="
echo "Deploying Traefik and IngressRoutes"
echo "=========================================="

# Step 1: Install Traefik
echo ""
echo "Step 1: Installing Traefik..."
bash 6_traefik/00-install-traefik.sh

# Wait a bit for Traefik to be fully ready
echo ""
echo "Waiting 10 seconds for Traefik to stabilize..."
sleep 10

# Step 2: Apply JupyterHub IngressRoute
echo ""
echo "Step 2: Applying JupyterHub IngressRoute..."
kubectl apply -f 6_traefik/01-jupyterhub-ingressroute.yaml

# Step 3: Apply Grafana IngressRoute
echo ""
echo "Step 3: Applying Grafana IngressRoute..."
kubectl apply -f 6_traefik/02-grafana-ingressroute.yaml

# Step 4: Apply Auth Secrets
echo ""
echo "Step 4: Applying Authentication Secrets..."
kubectl apply -f 6_traefik/06-auth-secrets.yaml

# Step 5: Apply Spark IngressRoute
echo ""
echo "Step 5: Applying Spark IngressRoute..."
kubectl apply -f 6_traefik/03-spark-ingressroute.yaml

# Step 6: Apply HDFS IngressRoute
echo ""
echo "Step 6: Applying HDFS IngressRoute..."
kubectl apply -f 6_traefik/04-hdfs-ingressroute.yaml

# Step 7: Apply PostgreSQL/pgAdmin IngressRoute
echo ""
echo "Step 7: Applying PostgreSQL/pgAdmin IngressRoute..."
kubectl apply -f 6_traefik/05-postgres-ingressroute.yaml

echo ""
echo "=========================================="
echo "Traefik deployment completed!"
echo "=========================================="
echo ""
echo "Service URLs:"
echo "  - JupyterHub:  https://jupyter.mireu.xyz"
echo "  - Grafana:     https://grafana.mireu.xyz"
echo "  - Spark UI:    https://spark.mireu.xyz (Basic Auth: admin/spark@mireu)"
echo "  - HDFS UI:     https://hdfs.mireu.xyz (Basic Auth: admin/hdfs@mireu)"
echo "  - pgAdmin:     https://pg.mireu.xyz (Login: admin@mireu.xyz/admin123!@#)"
echo "  - Traefik:     https://traefik.mireu.xyz"
echo ""
echo "Get Traefik LoadBalancer IP:"
echo "  kubectl get svc -n traefik-system traefik"
echo ""
echo "Configure your DNS or /etc/hosts:"
echo "  <LOADBALANCER_IP> jupyter.mireu.xyz"
echo "  <LOADBALANCER_IP> grafana.mireu.xyz"
echo "  <LOADBALANCER_IP> spark.mireu.xyz"
echo "  <LOADBALANCER_IP> hdfs.mireu.xyz"
echo "  <LOADBALANCER_IP> pg.mireu.xyz"
echo "  <LOADBALANCER_IP> traefik.mireu.xyz"
