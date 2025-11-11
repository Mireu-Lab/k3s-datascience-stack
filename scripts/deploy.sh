#!/bin/bash
# K3s Data Science Stack 배포 스크립트

set -e

echo "=========================================="
echo "K3s Data Science Stack - Deployment"
echo "=========================================="

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 함수 정의
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# 1. PostgreSQL 배포
print_step "1/6 Deploying PostgreSQL..."

read -p "Deploy PostgreSQL? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Installing PostgreSQL..."
    
    helm upgrade --install postgresql bitnami/postgresql \
      -f k8s/02-postgresql/values.yaml \
      -n storage \
      --create-namespace \
      --wait \
      --timeout 10m
    
    print_info "PostgreSQL deployed successfully"
else
    print_warn "PostgreSQL deployment skipped"
fi

# 2. Hadoop 배포
print_step "2/6 Deploying Apache Hadoop..."

read -p "Deploy Hadoop? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Creating HDFS directories..."
    
    helm upgrade --install hadoop bitnami/hadoop \
      -f k8s/03-hadoop/values.yaml \
      -n storage \
      --create-namespace \
      --wait \
      --timeout 10m
    
    print_info "Waiting for Hadoop to be ready..."
    sleep 30
    
    print_info "Creating HDFS directories for Spark..."
    kubectl exec -n storage hadoop-namenode-0 -- hdfs dfs -mkdir -p /spark-logs || true
    kubectl exec -n storage hadoop-namenode-0 -- hdfs dfs -mkdir -p /spark-warehouse || true
    kubectl exec -n storage hadoop-namenode-0 -- hdfs dfs -chmod 777 /spark-logs || true
    kubectl exec -n storage hadoop-namenode-0 -- hdfs dfs -chmod 777 /spark-warehouse || true
    
    print_info "Hadoop deployed successfully"
else
    print_warn "Hadoop deployment skipped"
fi

# 3. Spark 배포
print_step "3/6 Deploying Apache Spark..."

read -p "Deploy Spark? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Installing Spark..."
    
    helm upgrade --install spark bitnami/spark \
      -f k8s/04-spark/values.yaml \
      -n datascience \
      --create-namespace \
      --wait \
      --timeout 10m
    
    print_info "Spark deployed successfully"
else
    print_warn "Spark deployment skipped"
fi

# 4. JupyterHub 배포
print_step "4/6 Deploying JupyterHub..."

read -p "Deploy JupyterHub? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Applying secrets..."
    kubectl apply -f k8s/05-jupyterhub/secrets.yaml || print_warn "Secrets file not found or already exists"
    
    print_info "Installing JupyterHub..."
    
    helm upgrade --install jupyterhub jupyterhub/jupyterhub \
      -f k8s/05-jupyterhub/values.yaml \
      -n datascience \
      --create-namespace \
      --version 3.2.1 \
      --wait \
      --timeout 15m
    
    print_info "JupyterHub deployed successfully"
else
    print_warn "JupyterHub deployment skipped"
fi

# 5. Data Backup CronJobs 배포
print_step "5/6 Deploying Data Backup CronJobs..."

read -p "Deploy Data Backup CronJobs? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Creating backup CronJobs..."
    
    kubectl apply -f k8s/06-data-backup/cronjobs.yaml
    
    print_info "Data Backup CronJobs deployed successfully"
else
    print_warn "Data Backup CronJobs deployment skipped"
fi

# 6. Ingress 배포
print_step "6/6 Deploying Ingress..."

read -p "Deploy Ingress? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Creating Ingress resources..."
    
    kubectl apply -f k8s/07-ingress/ingress.yaml
    
    print_info "Ingress deployed successfully"
else
    print_warn "Ingress deployment skipped"
fi

# 7. 배포 상태 확인
echo ""
print_step "Checking deployment status..."
echo ""

echo "Namespaces:"
kubectl get namespaces
echo ""

echo "Storage Pods:"
kubectl get pods -n storage
echo ""

echo "Data Science Pods:"
kubectl get pods -n datascience
echo ""

echo "Ingress:"
kubectl get ingress -A
echo ""

echo "Certificates:"
kubectl get certificate -A
echo ""

echo "CronJobs:"
kubectl get cronjobs -n storage
echo ""

# 8. 접속 정보 출력
echo ""
echo "=========================================="
echo "Deployment Summary"
echo "=========================================="
echo ""
echo "Services deployed successfully!"
echo ""
echo "Access URLs (after DNS configuration):"
echo "  - JupyterHub:      https://jupyter.mireu.xyz"
echo "  - Spark Master:    https://spark.mireu.xyz"
echo "  - Spark History:   https://spark-history.mireu.xyz"
echo "  - Hadoop NameNode: https://hadoop.mireu.xyz"
echo ""
echo "Default credentials (CHANGE THESE!):"
echo "  - Spark/Hadoop Basic Auth: admin / admin"
echo ""
echo "Next steps:"
echo "  1. Configure DNS records in CloudFlare"
echo "  2. Wait for SSL certificates to be issued"
echo "  3. Change default passwords"
echo "  4. Configure Google OAuth credentials"
echo "  5. Set up GCP Storage for archival backups"
echo ""
echo "For detailed instructions, see README.md"
echo ""
echo "=========================================="
echo "Deployment completed!"
echo "=========================================="
