#!/bin/bash
# K3s Data Science Stack 제거 스크립트

set -e

echo "=========================================="
echo "K3s Data Science Stack - Uninstall"
echo "=========================================="

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn "This will remove all deployed services and data!"
read -p "Are you sure you want to continue? (yes/no) " -r
echo
if [[ ! $REPLY == "yes" ]]; then
    echo "Uninstall cancelled"
    exit 0
fi

# JupyterHub 제거
print_info "Removing JupyterHub..."
helm uninstall jupyterhub -n datascience --wait || true
kubectl delete pvc -n datascience -l app=jupyterhub || true

# Spark 제거
print_info "Removing Spark..."
helm uninstall spark -n datascience --wait || true
kubectl delete pvc -n datascience -l app.kubernetes.io/name=spark || true

# Hadoop 제거
print_info "Removing Hadoop..."
helm uninstall hadoop -n storage --wait || true
kubectl delete pvc -n storage -l app.kubernetes.io/name=hadoop || true

# PostgreSQL 제거
print_info "Removing PostgreSQL..."
helm uninstall postgresql -n storage --wait || true
kubectl delete pvc -n storage -l app.kubernetes.io/name=postgresql || true

# CronJobs 제거
print_info "Removing CronJobs..."
kubectl delete -f k8s/06-data-backup/cronjobs.yaml || true

# Ingress 제거
print_info "Removing Ingress..."
kubectl delete -f k8s/07-ingress/ingress.yaml || true

# cert-manager 제거 (선택사항)
read -p "Remove cert-manager? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Removing cert-manager..."
    helm uninstall cert-manager -n cert-manager --wait || true
    kubectl delete namespace cert-manager || true
fi

# Namespaces 제거 (선택사항)
read -p "Remove namespaces? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Removing namespaces..."
    kubectl delete namespace datascience || true
    kubectl delete namespace storage || true
    kubectl delete namespace monitoring || true
fi

echo ""
echo "=========================================="
echo "Uninstall completed!"
echo "=========================================="
echo ""
print_warn "Note: Data in /mnt/nvme and /mnt/hdd has not been deleted"
print_warn "To remove data, run: sudo rm -rf /mnt/nvme/hot-data/* /mnt/hdd/cold-data/*"
