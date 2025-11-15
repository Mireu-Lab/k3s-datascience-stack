#!/bin/bash
set -e

export KUBECONFIG=/home/limmi/k3s-datascience-stack/k3s.yaml

echo "=========================================="
echo "K3s Data Science Stack Cleanup"
echo "=========================================="
echo ""
echo "WARNING: This will delete all deployed components!"
echo "Press Ctrl+C to cancel, or Enter to continue..."
read

echo ""
echo "Starting cleanup process..."

# 7. Keycloak & OAuth2 Proxy
echo ""
echo "[1/11] Removing Keycloak & OAuth2 Proxy..."
kubectl delete -f 7_keycloak/10-example-ingressroutes-with-jwt.yaml --ignore-not-found=true
kubectl delete -f 7_keycloak/09-jwt-middlewares.yaml --ignore-not-found=true
kubectl delete -f 7_keycloak/08-oauth2-proxy-ingressroute.yaml --ignore-not-found=true
kubectl delete -f 7_keycloak/04-keycloak-ingressroute.yaml --ignore-not-found=true
kubectl delete -f 7_keycloak/03-keycloak-clients.yaml --ignore-not-found=true
kubectl delete -f 7_keycloak/02-keycloak-realm.yaml --ignore-not-found=true
kubectl delete -f 7_keycloak/01-keycloak-instance.yaml --ignore-not-found=true
helm uninstall oauth2-proxy -n oauth2-proxy --ignore-not-found || true
helm uninstall keycloak-operator -n keycloak --ignore-not-found || true
kubectl delete namespace oauth2-proxy --ignore-not-found=true
kubectl delete namespace keycloak --ignore-not-found=true
kubectl delete pvc -n keycloak --all --ignore-not-found=true

# 6. Traefik
echo ""
echo "[2/11] Removing Traefik..."
kubectl delete -f 6_traefik/05-postgres-ingressroute.yaml --ignore-not-found=true
kubectl delete -f 6_traefik/04-hdfs-ingressroute.yaml --ignore-not-found=true
kubectl delete -f 6_traefik/03-spark-ingressroute.yaml --ignore-not-found=true
kubectl delete -f 6_traefik/02-grafana-ingressroute.yaml --ignore-not-found=true
kubectl delete -f 6_traefik/01-jupyterhub-ingressroute.yaml --ignore-not-found=true
helm uninstall traefik -n kube-system --ignore-not-found || true
kubectl delete namespace traefik-system --ignore-not-found=true
kubectl delete namespace traefik --ignore-not-found=true

# 5. Grafana
echo ""
echo "[3/11] Removing Grafana..."
kubectl delete -f 5_grafana/03-dashboards.yaml --ignore-not-found=true
kubectl delete -f 5_grafana/02-datasources.yaml --ignore-not-found=true
kubectl delete -f 5_grafana/01-grafana-instance.yaml --ignore-not-found=true
helm uninstall grafana-operator -n grafana-operator --ignore-not-found || true
kubectl delete namespace grafana-operator --ignore-not-found=true
kubectl delete namespace grafana --ignore-not-found=true

# 4. JupyterHub
echo ""
echo "[4/11] Removing JupyterHub..."
helm uninstall jupyterhub -n jupyterhub --ignore-not-found || true
kubectl delete namespace jupyterhub --ignore-not-found=true
kubectl delete pvc -n jupyterhub --all --ignore-not-found=true

# 3. PostgreSQL & PgAdmin
echo ""
echo "[5/11] Removing PostgreSQL & PgAdmin..."
kubectl delete -f 3_postgres/06-pgadmin.yaml --ignore-not-found=true
kubectl delete -f 3_postgres/05-postgres-ingress.yaml --ignore-not-found=true
kubectl delete -f 3_postgres/04-scheduledbackup.yaml --ignore-not-found=true
kubectl delete -f 3_postgres/02-pooler.yaml --ignore-not-found=true
kubectl delete -f 3_postgres/01-postgres-cluster.yaml --ignore-not-found=true
kubectl delete -f 3_postgres/03-backup-secret.yaml --ignore-not-found=true
kubectl delete namespace cnpg-system --ignore-not-found=true
kubectl delete namespace postgres --ignore-not-found=true
kubectl delete pvc -l cnpg.io/cluster=postgres-cluster --ignore-not-found=true
kubectl delete pvc pgadmin-pvc -n default --ignore-not-found=true

# 2. Spark
echo ""
echo "[6/11] Removing Spark..."
kubectl delete -f 2_spark/04-spark-ingress.yaml --ignore-not-found=true
kubectl delete -f 2_spark/03-data-preprocessing-app.yaml --ignore-not-found=true
kubectl delete -f 2_spark/02-spark-cluster.yaml --ignore-not-found=true
kubectl delete -f 2_spark/01-spark-pi-example.yaml --ignore-not-found=true
kubectl delete -f 2_spark/00-spark-rbac.yaml --ignore-not-found=true
helm uninstall spark-kubernetes-operator -n spark-operator --ignore-not-found || true
kubectl delete namespace spark-operator --ignore-not-found=true
kubectl delete namespace spark --ignore-not-found=true

# 1. HDFS & Zookeeper
echo ""
echo "[7/11] Removing HDFS & Zookeeper..."
kubectl delete -f 1_hdfs/04-hdfs-ingress.yaml --ignore-not-found=true
kubectl delete -f 1_hdfs/03-data-lifecycle-cronjob.yaml --ignore-not-found=true
kubectl delete -f 1_hdfs/02-hdfs-cluster.yaml --ignore-not-found=true
kubectl delete -f 1_hdfs/01-zookeeper-znode.yaml --ignore-not-found=true
kubectl delete -f 1_hdfs/01-zookeeper-cluster.yaml --ignore-not-found=true

echo "Waiting for HDFS and Zookeeper resources to terminate..."
sleep 10

# Force delete pods to release PVC
echo "Force deleting HDFS and Zookeeper pods..."
kubectl delete pod -l app.kubernetes.io/name=zookeeper -n default --force --grace-period=0 --ignore-not-found=true
kubectl delete pod -l app.kubernetes.io/name=hdfs -n default --force --grace-period=0 --ignore-not-found=true

# Delete statefulsets to release PVC
echo "Deleting StatefulSets..."
kubectl delete statefulset --all -n default --ignore-not-found=true

# Force delete PVCs with finalizers
echo "Removing finalizers from PVCs..."
kubectl patch pvc -n default -l app.kubernetes.io/name=zookeeper -p '{"metadata":{"finalizers":null}}' --ignore-not-found || true
kubectl patch pvc -n default -l app.kubernetes.io/name=hdfs -p '{"metadata":{"finalizers":null}}' --ignore-not-found || true
echo "Deleting HDFS and Zookeeper PVCs..."
kubectl delete pvc -l app.kubernetes.io/managed-by=hdfs-operator -n default --ignore-not-found=true
kubectl delete pvc -l app.kubernetes.io/managed-by=zookeeper-operator -n default --ignore-not-found=true
kubectl delete pvc -l app.kubernetes.io/name=zookeeper -n default --ignore-not-found=true
kubectl delete pvc -l app.kubernetes.io/name=hdfs -n default --ignore-not-found=true

# Remove Stackable operators
echo "Removing Stackable operators..."
helm uninstall zookeeper-operator -n stackable-operators --ignore-not-found || true
helm uninstall hdfs-operator -n stackable-operators --ignore-not-found || true
helm uninstall commons-operator -n stackable-operators --ignore-not-found || true
helm uninstall secret-operator -n stackable-operators --ignore-not-found || true
kubectl delete namespace stackable-operators --ignore-not-found=true
kubectl delete namespace hdfs --ignore-not-found=true
kubectl delete namespace zookeeper --ignore-not-found=true

# 0. Ingress
echo ""
echo "[8/11] Removing Ingress NGINX..."
kubectl delete namespace ingress-nginx --ignore-not-found=true

echo ""
echo "Cleaning up remaining resources..."
# Force delete all pods first
kubectl delete pod --all -n default --force --grace-period=0 --ignore-not-found=true

# Delete all services in default namespace
echo "Deleting all services in default namespace..."
kubectl delete svc --all -n default --ignore-not-found=true

# Delete all deployments, statefulsets, daemonsets in default namespace
echo "Deleting all workloads in default namespace..."
kubectl delete deployment --all -n default --ignore-not-found=true
kubectl delete statefulset --all -n default --ignore-not-found=true
kubectl delete daemonset --all -n default --ignore-not-found=true
kubectl delete replicaset --all -n default --ignore-not-found=true

# Remove finalizers from all PVCs and delete
for pvc in $(kubectl get pvc -n default -o name 2>/dev/null); do
    kubectl patch $pvc -n default -p '{"metadata":{"finalizers":null}}' --ignore-not-found || true
done
kubectl delete pvc --all -n default --ignore-not-found=true

kubectl delete configmap --all -n default --ignore-not-found=true
kubectl delete secret --all -n default --ignore-not-found=true

# Additional namespaces cleanup
echo ""
echo "[9/11] Removing additional namespaces..."
kubectl delete namespace gpu-operator --ignore-not-found=true
kubectl delete namespace grafana-system --ignore-not-found=true

# Clean up Keycloak database and other resources
echo ""
echo "[10/11] Cleaning up remaining Keycloak/OAuth resources..."
kubectl delete secret -l app=keycloak -n default --ignore-not-found=true
kubectl delete configmap -l app=keycloak -n default --ignore-not-found=true
kubectl delete pvc -l app=keycloak -n default --ignore-not-found=true

# HELM REPO REMOVE
echo ""
echo "[11/11] Removing HELM repositories..."
helm repo remove stackable-operators || true
helm repo remove spark || true
helm repo remove cnpg || true
helm repo remove grafana || true
helm repo remove jupyterhub || true
helm repo remove keycloak-operator || true
helm repo remove oauth2-proxy || true


echo ""
echo "=========================================="
echo "Cleanup Complete!"
echo "=========================================="
echo ""
echo "Do you want to clean up disk directories? (y/n)"
read -r cleanup_disk

if [ "$cleanup_disk" = "y" ]; then
    echo ""
    echo "Cleaning up disk directories..."
    
    # Spark directories
    sudo rm -rf /mnt/nvme/spark-tmp/* 2>/dev/null || true
    sudo rm -rf /mnt/nvme/spark-warehouse/* 2>/dev/null || true
    sudo rm -rf /mnt/nvme/spark-events/* 2>/dev/null || true
    sudo rm -rf /mnt/nvme/spark-output/* 2>/dev/null || true
    sudo rm -rf /mnt/hdd/spark-output/* 2>/dev/null || true
    sudo rm -rf /mnt/gcs/spark-output/* 2>/dev/null || true
    
    # HDFS directories (if any)
    sudo rm -rf /mnt/nvme/hdfs/* 2>/dev/null || true
    sudo rm -rf /mnt/hdd/hdfs/* 2>/dev/null || true
    
    # PostgreSQL directories (if any)
    sudo rm -rf /mnt/nvme/postgres/* 2>/dev/null || true
    sudo rm -rf /mnt/hdd/postgres/* 2>/dev/null || true
    
    echo "Disk cleanup complete!"
fi

echo ""
echo "Verification commands:"
echo "  kubectl get all --all-namespaces"
echo "  kubectl get pvc --all-namespaces"
echo "  kubectl get namespace"
echo ""
